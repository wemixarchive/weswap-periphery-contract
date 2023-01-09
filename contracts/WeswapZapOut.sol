// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

import './interfaces/IWeswapZapOut.sol';
import './interfaces/IWWEMIX.sol';
import './interfaces/IWeswapRouter.sol';
import './interfaces/IWeswapPair.sol';
import './interfaces/IWeswapERC20.sol';
import './ZapBase.sol';

contract WeswapZapOut is IWeswapZapOut, ZapOutBase {
    using SafeERC20 for IERC20;

    uint256 private constant deadline = 0xf000000000000000000000000000000000000000000000000000000000000000;
    uint256 private constant permitAllowance = 79228162514260000000000000000;

    IWeswapRouter private immutable weswapRouter;
    address private immutable wwemixTokenAddress;

    constructor(
        address _router,
        address _wwemix,
        uint256 _goodwill,
        uint256 _affiliateSplit
    ) ZapBase(_goodwill, _affiliateSplit) {
        weswapRouter = IWeswapRouter(_router);
        wwemixTokenAddress = _wwemix;

        // approvedTargets[/* address */] = true;
    }

    /**
     * @notice Zap out in both tokens
     * @param fromPoolAddress Pool from which to remove liquidity
     * @param incomingLP Quantity of LP to remove from pool
     * @param affiliate Affiliate address
     * @return amountA Quantity of tokenA received after zapout
     * @return amountB Quantity of tokenB received after zapout
     */
    function ZapOut2PairToken(
        address fromPoolAddress,
        uint256 incomingLP,
        address affiliate
    ) public stopInEmergency returns (uint256 amountA, uint256 amountB) {
        IWeswapPair pair = IWeswapPair(fromPoolAddress);

        require(address(pair) != address(0), "Pool Cannot be Zero Address");

        // get reserves
        address token0 = pair.token0();
        address token1 = pair.token1();

        IERC20(fromPoolAddress).safeTransferFrom(
            msg.sender,
            address(this),
            incomingLP
        );

        _approveToken(fromPoolAddress, address(weswapRouter), incomingLP);

        if (token0 == wwemixTokenAddress || token1 == wwemixTokenAddress) {
            address _token = token0 == wwemixTokenAddress ? token1 : token0;
            (amountA, amountB) = weswapRouter.removeLiquidityWEMIX(
                _token,
                incomingLP,
                1,
                1,
                address(this),
                deadline
            );

            // subtract goodwill
            uint256 tokenGoodwill =
                _subtractGoodwill(_token, amountA, affiliate, true);
            uint256 wemixGoodwill =
                _subtractGoodwill(WEMIXAddress, amountB, affiliate, true);

            // send tokens
            IERC20(_token).safeTransfer(msg.sender, amountA - tokenGoodwill);
            Address.sendValue(payable(msg.sender), amountB - wemixGoodwill);
        } else {
            (amountA, amountB) = weswapRouter.removeLiquidity(
                token0,
                token1,
                incomingLP,
                1,
                1,
                address(this),
                deadline
            );

            // subtract goodwill
            uint256 tokenAGoodwill =
                _subtractGoodwill(token0, amountA, affiliate, true);
            uint256 tokenBGoodwill =
                _subtractGoodwill(token1, amountB, affiliate, true);

            // send tokens
            IERC20(token0).safeTransfer(msg.sender, amountA - tokenAGoodwill);
            IERC20(token1).safeTransfer(msg.sender, amountB - tokenBGoodwill);
        }
        emit zapOut(msg.sender, fromPoolAddress, token0, amountA);
        emit zapOut(msg.sender, fromPoolAddress, token1, amountB);
    }

    /**
     * @notice Zap out in tokens unproportionately
     * @param toTokenAddress Address of desired token
     * @param fromPoolAddress Pool from which to remove liquidity
     * @param incomingLP Quantity of LP to remove from pool
     * @param amountToSwap Quantity of tokens to swap
     * @param minToken0Rec Minimum quantity of token0 to receive
     * @param minToken1Rec Minimum quantity of token1 to receive
     * @param swapTargets Execution targets for swaps
     * @param swapData DEX swap data
     * @param affiliate Affiliate address
     * @param shouldSellEntireBalance If True transfers entrire allowable amount from another contract
     */
    function ZapOutUnproportionate2PairToken(
        address toTokenAddress,
        address fromPoolAddress,
        uint256 incomingLP,
        uint256 amountToSwap,
        uint256 minToken0Rec,
        uint256 minToken1Rec,
        address[] memory swapTargets,
        bytes[] memory swapData,
        address affiliate,
        bool shouldSellEntireBalance
    ) public stopInEmergency returns (uint256 token0Rec, uint256 token1Rec) {
        // avoids stack too deep errors
        // (uint256 amount0, uint256 amount1) =
        (token0Rec, token1Rec) =
            _removeLiquidity(
                fromPoolAddress,
                incomingLP,
                shouldSellEntireBalance
            );

        // swaps tokens to token
        (token0Rec, token1Rec) = _partialSwapTokens(
            fromPoolAddress,
            token0Rec,
            token1Rec,
            toTokenAddress,
            amountToSwap,
            swapTargets,
            swapData
        );
        require(token0Rec >= minToken0Rec, "High Slippage");
        require(token1Rec >= minToken1Rec, "High Slippage");

        address token0 = IWeswapPair(fromPoolAddress).token0();
        address token1 = IWeswapPair(fromPoolAddress).token1();

        // transfer toTokens to sender
        if (toTokenAddress == address(0)) {
            if (token0 != toTokenAddress) {
                (token0, token1) = (token1, token0);
                (token0Rec, token1Rec) = (token1Rec, token0Rec);
            }

            token0Rec -= _subtractGoodwill(
                WEMIXAddress,
                token0Rec,
                affiliate,
                true
            );
            token1Rec -= _subtractGoodwill(
                token1,
                token1Rec,
                affiliate,
                true
            );

            payable(msg.sender).transfer(token0Rec);
            IERC20(token1).safeTransfer(msg.sender, token1Rec);
        } else {
            token0Rec -= _subtractGoodwill(
                token0,
                token0Rec,
                affiliate,
                true
            );
            token1Rec -= _subtractGoodwill(
                token1,
                token1Rec,
                affiliate,
                true
            );

            IERC20(token0).safeTransfer(msg.sender, token0Rec);
            IERC20(token1).safeTransfer(msg.sender, token1Rec);
        }

        emit zapOut(msg.sender, fromPoolAddress, token0, token0Rec);
        emit zapOut(msg.sender, fromPoolAddress, token1, token1Rec);

        // return (token0Rec, token1Rec);
    }

    /**
     * @notice Zap out in tokens unproportionately
     * @param toTokenAddress Address of desired token
     * @param fromPoolAddress Pool from which to remove liquidity
     * @param incomingLP Quantity of LP to remove from pool
     * @param amountToSwap Quantity of tokens to swap
     * @param minToken0Rec Minimum quantity of token0 to receive
     * @param minToken1Rec Minimum quantity of token1 to receive
     * @param permitSig Signature for permit
     * @param swapTargets Execution targets for swaps
     * @param swapData DEX swap data
     * @param affiliate Affiliate address
     */
    function ZapOutUnproportionate2PairTokenWithPermit(
        address toTokenAddress,
        address fromPoolAddress,
        uint256 incomingLP,
        uint256 amountToSwap,
        uint256 minToken0Rec,
        uint256 minToken1Rec,
        bytes calldata permitSig,
        address[] memory swapTargets,
        bytes[] memory swapData,
        address affiliate
    ) external stopInEmergency returns (uint256 token0Rec, uint256 token1Rec) {
        _permit(fromPoolAddress, permitAllowance, permitSig);

        return (
            ZapOutUnproportionate2PairToken(
                toTokenAddress,
                fromPoolAddress,
                incomingLP,
                amountToSwap,
                minToken0Rec,
                minToken1Rec,
                swapTargets,
                swapData,
                affiliate,
                false
            )
        );
    }

    /**
     * @notice Zap out in a single token
     * @param toTokenAddress Address of desired token
     * @param fromPoolAddress Pool from which to remove liquidity
     * @param incomingLP Quantity of LP to remove from pool
     * @param minTokensRec Minimum quantity of tokens to receive
     * @param swapTargets Execution targets for swaps
     * @param swapData DEX swap data
     * @param affiliate Affiliate address
     * @param shouldSellEntireBalance If True transfers entrire allowable amount from another contract
     */
    function ZapOut(
        address toTokenAddress,
        address fromPoolAddress,
        uint256 incomingLP,
        uint256 minTokensRec,
        address[] memory swapTargets,
        bytes[] memory swapData,
        address affiliate,
        bool shouldSellEntireBalance
    ) public stopInEmergency returns (uint256 tokensRec) {
        (uint256 amount0, uint256 amount1) =
            _removeLiquidity(
                fromPoolAddress,
                incomingLP,
                shouldSellEntireBalance
            );

        //swaps tokens to token
        tokensRec = _swapTokens(
            fromPoolAddress,
            amount0,
            amount1,
            toTokenAddress,
            swapTargets,
            swapData
        );
        require(tokensRec >= minTokensRec, "High Slippage");

        uint256 totalGoodwillPortion;

        // transfer toTokens to sender
        if (toTokenAddress == address(0)) {
            totalGoodwillPortion = _subtractGoodwill(
                WEMIXAddress,
                tokensRec,
                affiliate,
                true
            );

            payable(msg.sender).transfer(tokensRec - totalGoodwillPortion);
        } else {
            totalGoodwillPortion = _subtractGoodwill(
                toTokenAddress,
                tokensRec,
                affiliate,
                true
            );

            IERC20(toTokenAddress).safeTransfer(
                msg.sender,
                tokensRec - totalGoodwillPortion
            );
        }

        tokensRec = tokensRec - totalGoodwillPortion;

        emit zapOut(msg.sender, fromPoolAddress, toTokenAddress, tokensRec);

        return tokensRec;
    }

    function _swapTokensSimple(
        address fromPoolAddress,
        uint256 amount0,
        uint256 amount1,
        address toToken,
        address[] calldata path,
        function (
            uint256, // amountIn
            uint256, // amountOutMin
            address[] memory, // path
            address, // to
            uint256 // deadline
        ) external returns (uint256[] memory) swapFunc
    ) internal returns (uint256 tokensBought) {
        address token0 = IWeswapPair(fromPoolAddress).token0();
        address token1 = IWeswapPair(fromPoolAddress).token1();

        //swap token0 to toToken
        if (token0 == toToken) {
            tokensBought += amount0;
        } else {
            _approveToken(token0, address(weswapRouter), amount0);

            //swap token using swap
            tokensBought += swapFunc(
                amount0,
                1,
                path,
                address(this),
                deadline
            )[path.length - 1];
        }

        //swap token1 to toToken
        if (token1 == toToken) {
            tokensBought += amount1;
        } else {
            _approveToken(token1, address(weswapRouter), amount1);

            //swap token using swap
            tokensBought += swapFunc(
                amount1,
                1,
                path,
                address(this),
                deadline
            )[path.length - 1];
        }
    }

    /**
     * @notice Zap out in a single token (token0-token1 pair always exist)
     * @param toTokenAddress Address of desired token
     * @param fromPoolAddress Pool from which to remove liquidity
     * @param incomingLP Quantity of LP to remove from pool
     * @param path Swap path
     * @param minTokensRec Minimum quantity of tokens to receive
     * @param affiliate Affiliate address
     * @param shouldSellEntireBalance If True transfers entrire allowable amount from another contract
     */
    function ZapOutSimple(
        address toTokenAddress,
        address fromPoolAddress,
        uint256 incomingLP,
        address[] calldata path,
        uint256 minTokensRec,
        address affiliate,
        bool shouldSellEntireBalance
    ) external stopInEmergency returns (uint256 tokensRec) {
        (uint256 amount0, uint256 amount1) =
            _removeLiquidity(
                fromPoolAddress,
                incomingLP,
                shouldSellEntireBalance
            );

        //swaps tokens to token
        if (toTokenAddress == address(0)) {
            tokensRec = _swapTokensSimple(
                fromPoolAddress,
                amount0,
                amount1,
                wwemixTokenAddress,
                path,
                weswapRouter.swapExactTokensForWEMIX
            );
            uint256 amount = IERC20(wwemixTokenAddress).balanceOf(address(this));
            if (amount != 0) { IWWEMIX(wwemixTokenAddress).withdraw(amount); }
        }
        else {
            tokensRec = _swapTokensSimple(
                fromPoolAddress,
                amount0,
                amount1,
                toTokenAddress,
                path,
                weswapRouter.swapExactTokensForTokens
            );
        }
        require(tokensRec >= minTokensRec, "High Slippage");

        // transfer toTokens to sender
        if (toTokenAddress == address(0)) {
            payable(msg.sender).transfer(tokensRec);
        } else {
            IERC20(toTokenAddress).safeTransfer(msg.sender, tokensRec);
        }

        emit zapOut(msg.sender, fromPoolAddress, toTokenAddress, tokensRec);

        return tokensRec;
    }

    /**
     * @notice Zap out in both tokens with permit
     * @param fromPoolAddress Pool from which to remove liquidity
     * @param incomingLP Quantity of LP to remove from pool
     * @param affiliate Affiliate address to share fees
     * @param permitSig Signature for permit
     * @return amountA Quantity of tokenA received
     * @return amountB Quantity of tokenB received
     */
    function ZapOut2PairTokenWithPermit(
        address fromPoolAddress,
        uint256 incomingLP,
        address affiliate,
        bytes calldata permitSig
    ) external stopInEmergency returns (uint256 amountA, uint256 amountB) {
        _permit(fromPoolAddress, permitAllowance, permitSig);

        (amountA, amountB) = ZapOut2PairToken(
            fromPoolAddress,
            incomingLP,
            affiliate
        );
    }

    /**
     * @notice Zap out in a single token with permit
     * @param toTokenAddress Address of desired token
     * @param fromPoolAddress Pool from which to remove liquidity
     * @param incomingLP Quantity of LP to remove from pool
     * @param minTokensRec Minimum quantity of tokens to receive
     * @param permitSig Signature for permit
     * @param swapTargets Execution targets for swaps
     * @param swapData DEX swap data
     * @param affiliate Affiliate address
     */
    function ZapOutWithPermit(
        address toTokenAddress,
        address fromPoolAddress,
        uint256 incomingLP,
        uint256 minTokensRec,
        bytes calldata permitSig,
        address[] memory swapTargets,
        bytes[] memory swapData,
        address affiliate
    ) external stopInEmergency returns (uint256) {
        // permit
        _permit(fromPoolAddress, permitAllowance, permitSig);

        return (
            ZapOut(
                toTokenAddress,
                fromPoolAddress,
                incomingLP,
                minTokensRec,
                swapTargets,
                swapData,
                affiliate,
                false
            )
        );
    }

    function _permit(
        address fromPoolAddress,
        uint256 amountIn,
        bytes memory permitSig
    ) internal {
        require(permitSig.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(permitSig, 32))
            s := mload(add(permitSig, 64))
            v := byte(0, mload(add(permitSig, 96)))
        }
        IWeswapERC20(fromPoolAddress).permit(
            msg.sender,
            address(this),
            amountIn,
            deadline,
            v,
            r,
            s
        );
    }

    function _removeLiquidity(
        address fromPoolAddress,
        uint256 incomingLP,
        bool shouldSellEntireBalance
    ) internal returns (uint256 amount0, uint256 amount1) {
        IWeswapPair pair = IWeswapPair(fromPoolAddress);

        require(address(pair) != address(0), "Pool Cannot be Zero Address");

        address token0 = pair.token0();
        address token1 = pair.token1();

        _pullTokens(fromPoolAddress, incomingLP, shouldSellEntireBalance);

        _approveToken(fromPoolAddress, address(weswapRouter), incomingLP);

        (amount0, amount1) = weswapRouter.removeLiquidity(
            token0,
            token1,
            incomingLP,
            1,
            1,
            address(this),
            deadline
        );
        require(amount0 > 0 && amount1 > 0, "Removed Insufficient Liquidity");
    }

    function _swapTokens(
        address fromPoolAddress,
        uint256 amount0,
        uint256 amount1,
        address toToken,
        address[] memory swapTargets,
        bytes[] memory swapData
    ) internal returns (uint256 tokensBought) {
        address token0 = IWeswapPair(fromPoolAddress).token0();
        address token1 = IWeswapPair(fromPoolAddress).token1();

        //swap token0 to toToken
        if (token0 == toToken) {
            tokensBought = tokensBought + amount0;
        } else {
            //swap token using swap
            tokensBought =
                tokensBought +
                _fillQuote(
                    token0,
                    toToken,
                    amount0,
                    swapTargets[0],
                    swapData[0]
                );
        }

        //swap token1 to toToken
        if (token1 == toToken) {
            tokensBought = tokensBought + amount1;
        } else {
            //swap token using swap
            tokensBought =
                tokensBought +
                _fillQuote(
                    token1,
                    toToken,
                    amount1,
                    swapTargets[1],
                    swapData[1]
                );
        }
    }

    // must be either (token0 == toToken) or (token1 == toToken)
    function _partialSwapTokens(
        address fromPoolAddress,
        uint256 amount0,
        uint256 amount1,
        address toToken,
        uint256 amountToSwap,
        address[] memory swapTargets,
        bytes[] memory swapData
    ) internal returns (uint256 token0Bought, uint256 token1Bought) {
        address token0 = IWeswapPair(fromPoolAddress).token0();
        address token1 = IWeswapPair(fromPoolAddress).token1();

        require((token0 == toToken) || (token1 == toToken), "Error: _partialSwapTokens");

        if (token0 == toToken) { //swap token1 to token0
            token0Bought = amount0;

            //swap token using swap
            token0Bought =
                _fillQuote(
                    token1, // from
                    toToken, // to
                    amountToSwap,
                    swapTargets[0],
                    swapData[0]
                ) + amount0;
            token1Bought = amount1 - amountToSwap;
        } else { //swap token0 to token1
            token0Bought = amount0;

            //swap token using swap
            token1Bought =
                _fillQuote(
                    token0, // from
                    toToken, // to
                    amountToSwap,
                    swapTargets[1],
                    swapData[1]
                ) + amount1;
            token0Bought = amount0 - amountToSwap;
        }
    }

    function _fillQuote(
        address fromTokenAddress,
        address toToken,
        uint256 amount,
        address swapTarget,
        bytes memory swapData
    ) internal returns (uint256) {
        if (fromTokenAddress == wwemixTokenAddress && toToken == address(0)) {
            IWWEMIX(wwemixTokenAddress).withdraw(amount);
            return amount;
        }

        uint256 valueToSend;
        if (fromTokenAddress == address(0)) {
            valueToSend = amount;
        } else {
            _approveToken(fromTokenAddress, swapTarget, amount);
        }

        uint256 initialBalance = _getBalance(toToken);

        require(approvedTargets[swapTarget], "Target not Authorized");
        (bool success, ) = swapTarget.call{ value: valueToSend }(swapData);
        require(success, "Error Swapping Tokens");

        uint256 finalBalance = _getBalance(toToken) - initialBalance;

        require(finalBalance > 0, "Swapped to Invalid Intermediate");

        return finalBalance;
    }

    /**
     * @notice Utility function to determine quantity and addresses of tokens being removed
     * @param fromPoolAddress Pool from which to remove liquidity
     * @param liquidity Quantity of LP tokens to remove.
     * @return amountA Quantity of tokenA removed
     * @return amountB Quantity of tokenB removed
     * @return token0 Address of the underlying token to be removed
     * @return token1 Address of the underlying token to be removed
     */
    function removeLiquidityReturn(
        address fromPoolAddress,
        uint256 liquidity
    ) external view returns (uint256 amountA, uint256 amountB, address token0, address token1) {
        IWeswapPair pair = IWeswapPair(fromPoolAddress);
        token0 = pair.token0();
        token1 = pair.token1();

        uint256 balance0 = IERC20(token0).balanceOf(fromPoolAddress);
        uint256 balance1 = IERC20(token1).balanceOf(fromPoolAddress);

        uint256 _totalSupply = IWeswapERC20(fromPoolAddress).totalSupply();

        amountA = (liquidity * balance0) / _totalSupply;
        amountB = (liquidity * balance1) / _totalSupply;
    }
}
