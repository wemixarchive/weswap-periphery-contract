// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

import './libraries/WeswapLibrary.sol';
import './libraries/TransferHelper.sol';
import './interfaces/IWeswapRouter.sol';
import './interfaces/IWeswapERC20.sol';
import './interfaces/IWWEMIX.sol';

contract WeswapRouter is IWeswapRouter {
    address public immutable factory;
    address public immutable WWEMIX;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, 'WeswapRouter: EXPIRED');
        _;
    }

    constructor(address _factory, address _WWEMIX) {
        factory = _factory;
        WWEMIX = _WWEMIX;
    }

    receive() external payable {
        assert(msg.sender == WWEMIX); // only accept WEMIX via fallback from the WWEMIX contract
        emit Receive(msg.sender, msg.value);
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal virtual returns (uint256 amountA, uint256 amountB) {

        (uint256 reserveA, uint256 reserveB) = WeswapLibrary.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = WeswapLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'WeswapRouter: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = WeswapLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'WeswapRouter: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = WeswapLibrary.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IWeswapPair(pair).mint(to);

        emit AddLiquidityReturn(amountA, amountB, liquidity);
    }
    function addLiquidityWEMIX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountWEMIXMin,
        address to,
        uint256 deadline
    ) external virtual override payable ensure(deadline) returns (uint256 amountToken, uint256 amountWEMIX, uint256 liquidity) {
        (amountToken, amountWEMIX) = _addLiquidity(
            token,
            WWEMIX,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountWEMIXMin
        );
        address pair = WeswapLibrary.pairFor(factory, token, WWEMIX);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWWEMIX(WWEMIX).deposit{value: amountWEMIX}();
        assert(IWWEMIX(WWEMIX).transfer(pair, amountWEMIX));
        liquidity = IWeswapPair(pair).mint(to);
        // refund dust eth, if any
        unchecked {
            if (msg.value > amountWEMIX) TransferHelper.safeTransferWEMIX(msg.sender, msg.value - amountWEMIX);
        }
        
        emit AddLiquidityReturn(amountToken, amountWEMIX, liquidity);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountA, uint256 amountB) {
        address pair = WeswapLibrary.pairFor(factory, tokenA, tokenB);
        IWeswapERC20(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint256 amount0, uint256 amount1) = IWeswapPair(pair).burn(to);
        (address token0,) = WeswapLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'WeswapRouter: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'WeswapRouter: INSUFFICIENT_B_AMOUNT');

        emit RemoveLiquidityReturn(amountA, amountB);
    }
    function removeLiquidityWEMIX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountWEMIXMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountToken, uint256 amountWEMIX) {
        (amountToken, amountWEMIX) = removeLiquidity(
            token,
            WWEMIX,
            liquidity,
            amountTokenMin,
            amountWEMIXMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWWEMIX(WWEMIX).withdraw(amountWEMIX);
        TransferHelper.safeTransferWEMIX(to, amountWEMIX);

        emit RemoveLiquidityReturn(amountToken, amountWEMIX);
    }
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint256 amountA, uint256 amountB) {
        address pair = WeswapLibrary.pairFor(factory, tokenA, tokenB);
        uint256 value = approveMax ? type(uint256).max : liquidity;
        IWeswapERC20(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);

        emit RemoveLiquidityReturn(amountA, amountB);
    }
    function removeLiquidityWEMIXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountWEMIXMin,
        address to,
        uint256 deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint256 amountToken, uint256 amountWEMIX) {
        address pair = WeswapLibrary.pairFor(factory, token, WWEMIX);
        uint256 value = approveMax ? type(uint256).max : liquidity;
        IWeswapERC20(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountWEMIX) = removeLiquidityWEMIX(token, liquidity, amountTokenMin, amountWEMIXMin, to, deadline);

        emit RemoveLiquidityReturn(amountToken, amountWEMIX);
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint256[] memory amounts, address[] memory path, address _to) internal virtual {
        unchecked {
            for (uint256 i; i < path.length - 1; i++) {
                (address input, address output) = (path[i], path[i + 1]);
                (address token0,) = WeswapLibrary.sortTokens(input, output);
                uint256 amountOut = amounts[i + 1];
                (uint256 amount0Out, uint256 amount1Out) = input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
                address to = i < path.length - 2 ? WeswapLibrary.pairFor(factory, output, path[i + 2]) : _to;
                IWeswapPair(WeswapLibrary.pairFor(factory, input, output)).swap(
                    amount0Out, amount1Out, to, new bytes(0)
                );
            }
        }
    }
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
        amounts = WeswapLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'WeswapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, WeswapLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
        amounts = WeswapLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'WeswapRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, WeswapLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapExactWEMIXForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        require(path[0] == WWEMIX, 'WeswapRouter: INVALID_PATH');
        amounts = WeswapLibrary.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'WeswapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWWEMIX(WWEMIX).deposit{value: amounts[0]}();
        assert(IWWEMIX(WWEMIX).transfer(WeswapLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }
    function swapTokensForExactWEMIX(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        require(path[path.length - 1] == WWEMIX, 'WeswapRouter: INVALID_PATH');
        amounts = WeswapLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'WeswapRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, WeswapLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWWEMIX(WWEMIX).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferWEMIX(to, amounts[amounts.length - 1]);
    }
    function swapExactTokensForWEMIX(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        require(path[path.length - 1] == WWEMIX, 'WeswapRouter: INVALID_PATH');
        amounts = WeswapLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'WeswapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, WeswapLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWWEMIX(WWEMIX).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferWEMIX(to, amounts[amounts.length - 1]);
    }
    function swapWEMIXForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        require(path[0] == WWEMIX, 'WeswapRouter: INVALID_PATH');
        amounts = WeswapLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, 'WeswapRouter: EXCESSIVE_INPUT_AMOUNT');
        IWWEMIX(WWEMIX).deposit{value: amounts[0]}();
        assert(IWWEMIX(WWEMIX).transfer(WeswapLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferWEMIX(msg.sender, msg.value - amounts[0]);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure virtual override returns (uint256 amountB) {
        return WeswapLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        external
        pure
        virtual
        override
        returns (uint256 amountOut)
    {
        return WeswapLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut)
        external
        pure
        virtual
        override
        returns (uint256 amountIn)
    {
        return WeswapLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        virtual
        override
        returns (uint256[] memory amounts)
    {
        return WeswapLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint256 amountOut, address[] memory path)
        external
        view
        virtual
        override
        returns (uint256[] memory amounts)
    {
        return WeswapLibrary.getAmountsIn(factory, amountOut, path);
    }
}
