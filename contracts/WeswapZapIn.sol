// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

import './libraries/Math.sol';
import './interfaces/IWeswapZapIn.sol';
import './interfaces/IWWEMIX.sol';
import './interfaces/IWeswapFactory.sol';
import './interfaces/IWeswapRouter.sol';
import './interfaces/IWeswapPair.sol';
import './interfaces/IWeswapERC20.sol';
import './ZapBase.sol';

contract WeswapZapIn is IWeswapZapIn, ZapInBase {
    using SafeERC20 for IERC20;

    uint256 private constant deadline = 0xf000000000000000000000000000000000000000000000000000000000000000;

    IWeswapFactory private immutable weswapFactory;
    IWeswapRouter private immutable weswapRouter;
    address private immutable wwemixTokenAddress;

    constructor(
        address _factory,
        address _router,
        address _wwemix,
        uint256 _goodwill,
        uint256 _affiliateSplit
    ) ZapBase(_goodwill, _affiliateSplit) {
        weswapFactory = IWeswapFactory(_factory);
        weswapRouter = IWeswapRouter(_router);
        wwemixTokenAddress = _wwemix;

        // approvedTargets[/* address */] = true;
    }

    /**
     * @notice This function is used to invest in given Weswap pair through WEMIX/ERC20 Tokens;
     * tokenA should be valuable than tokenB (swap a into b)
     * @param _FromTokenAContractAddress The ERC20 token used for investment (address(0x00) if WEMIX)
     * @param _FromTokenBContractAddress The ERC20 token used for investment (address(0x00) if WEMIX)
     * @param _pairAddress The Weswap pair address
     * @param _amountA The amount of fromToken to invest
     * @param _amountB The amount of fromToken to invest
     * @param _minPoolTokens Reverts if less tokens received than this
     * @param _swapTarget Excecution target for the first swap
     * @param swapData DEX quote data
     * @param transferResidual Set false to save gas by donating the residual remaining after a Zap
     * @param shouldSellEntireBalance If True transfers entrire allowable amount from another contract
     * @return Amount of LP bought
     */
    function ZapInUnproportionate2PairToken(
        address _FromTokenAContractAddress,
        address _FromTokenBContractAddress,
        address _pairAddress,
        uint256 _amountA,
        uint256 _amountB,
        uint256 _minPoolTokens,
        address _swapTarget,
        bytes calldata swapData,
        bool transferResidual,
        bool shouldSellEntireBalance
    ) external payable stopInEmergency returns (uint256) {
        uint256 LPBought;
        {
        uint256 toInvestA =
            _pullTokens(
                _FromTokenAContractAddress,
                _amountA,
                address(0), // affiliate
                true,
                shouldSellEntireBalance
            );

        uint256 toInvestB =
            _pullTokens(
                _FromTokenBContractAddress,
                _amountB,
                address(0), // affiliate
                true,
                shouldSellEntireBalance
            );

        LPBought =
            _performZapInUnproportionate2PairToken(
                _FromTokenAContractAddress,
                _FromTokenBContractAddress,
                _pairAddress,
                toInvestA,
                toInvestB,
                _swapTarget,
                swapData,
                transferResidual
            );
        }
        require(LPBought >= _minPoolTokens, "High Slippage");

        emit zapIn(msg.sender, _pairAddress, LPBought);

        IERC20(_pairAddress).safeTransfer(msg.sender, LPBought);
        return LPBought;
    }

    /**
     * @notice This function is used to invest in given Weswap pair through WEMIX/ERC20 Tokens
     * @param _FromTokenContractAddress The ERC20 token used for investment (address(0x00) if WEMIX)
     * @param _pairAddress The Weswap pair address
     * @param _amount The amount of fromToken to invest
     * @param _minPoolTokens Reverts if less tokens received than this
     * @param _swapTarget Excecution target for the first swap
     * @param swapData DEX quote data
     * @param affiliate Affiliate address
     * @param transferResidual Set false to save gas by donating the residual remaining after a Zap
     * @param shouldSellEntireBalance If True transfers entrire allowable amount from another contract
     * @return Amount of LP bought
     */
    function ZapIn(
        address _FromTokenContractAddress,
        address _pairAddress,
        uint256 _amount,
        uint256 _minPoolTokens,
        address _swapTarget,
        bytes calldata swapData,
        address affiliate,
        bool transferResidual,
        bool shouldSellEntireBalance
    ) external payable stopInEmergency returns (uint256) {
        uint256 toInvest =
            _pullTokens(
                _FromTokenContractAddress,
                _amount,
                affiliate,
                true,
                shouldSellEntireBalance
            );

        uint256 LPBought =
            _performZapIn(
                _FromTokenContractAddress,
                _pairAddress,
                toInvest,
                _swapTarget,
                swapData,
                transferResidual
            );
        require(LPBought >= _minPoolTokens, "High Slippage");

        emit zapIn(msg.sender, _pairAddress, LPBought);

        IERC20(_pairAddress).safeTransfer(msg.sender, LPBought);
        return LPBought;
    }

    function _getPairTokens(
        address _pairAddress
    ) internal view returns (address token0, address token1) {
        IWeswapPair wePair = IWeswapPair(_pairAddress);
        token0 = wePair.token0();
        token1 = wePair.token1();

        require(
            _pairAddress == weswapFactory.getPair(token0, token1),
            "WeswapZapIn::_getPairTokens: INVALID_PAIR"
        );
    }

    function _performZapIn(
        address _FromTokenContractAddress,
        address _pairAddress,
        uint256 _amount,
        address _swapTarget,
        bytes memory swapData,
        bool transferResidual
    ) internal returns (uint256) {
        uint256 intermediateAmt;
        address intermediateToken;
        (address _ToWeswapToken0, address _ToWeswapToken1) =
            _getPairTokens(_pairAddress);

        if (
            _FromTokenContractAddress != _ToWeswapToken0 &&
            _FromTokenContractAddress != _ToWeswapToken1
        ) {
            // swap to intermediate
            (intermediateAmt, intermediateToken) = _fillQuote(
                _FromTokenContractAddress,
                _pairAddress,
                _amount,
                _swapTarget,
                swapData
            );
        } else {
            intermediateToken = _FromTokenContractAddress;
            intermediateAmt = _amount;
        }

        // divide intermediate into appropriate amount to add liquidity
        (uint256 token0Bought, uint256 token1Bought) =
            _swapIntermediate(
                intermediateToken,
                _ToWeswapToken0,
                _ToWeswapToken1,
                intermediateAmt
            );

        return
            _weDeposit(
                _ToWeswapToken0,
                _ToWeswapToken1,
                token0Bought,
                token1Bought,
                transferResidual
            );
    }

    function _performZapInUnproportionate2PairToken(
        address _FromTokenAContractAddress,
        address _FromTokenBContractAddress,
        address _pairAddress,
        uint256 _amountA,
        uint256 _amountB,
        address _swapTarget,
        bytes memory swapData,
        bool transferResidual
    ) internal returns (uint256) {
        uint256 intermediateAmtA;
        uint256 intermediateAmtB;
        address intermediateTokenFrom;
        (address _ToWeswapToken0, address _ToWeswapToken1) =
            _getPairTokens(_pairAddress);

        if (
            _FromTokenAContractAddress != _ToWeswapToken0 &&
            _FromTokenAContractAddress != _ToWeswapToken1
        ) {
            // revert("ZapIn: not allowed intermediate (stack too deep)");
            // swap to intermediate
            (intermediateAmtA, intermediateTokenFrom) = _fillQuote(
                _FromTokenAContractAddress,
                _pairAddress,
                _amountA,
                _swapTarget,
                swapData
            );
        } else {
            intermediateTokenFrom = _FromTokenAContractAddress;
            intermediateAmtA = _amountA;
        }

        if (
            _FromTokenBContractAddress != _ToWeswapToken0 &&
            _FromTokenBContractAddress != _ToWeswapToken1
        ) {
            (intermediateAmtB,) = _fillQuote(
                _FromTokenBContractAddress,
                _pairAddress,
                _amountB,
                _swapTarget,
                swapData
            );
        } else {
            intermediateAmtB = _amountB;
        }

        // divide intermediate into appropriate amount to add liquidity
        (uint256 token0Bought, uint256 token1Bought) =
            _partialSwapIntermediate(
                intermediateTokenFrom,
                _ToWeswapToken0,
                _ToWeswapToken1,
                intermediateAmtA,
                intermediateAmtB
            );

        return
            _weDeposit(
                _ToWeswapToken0,
                _ToWeswapToken1,
                token0Bought,
                token1Bought,
                transferResidual
            );
    }

    function _weDeposit(
        address _ToWepoolToken0,
        address _ToWepoolToken1,
        uint256 token0Bought,
        uint256 token1Bought,
        bool transferResidual
    ) internal returns (uint256) {
        _approveToken(_ToWepoolToken0, address(weswapRouter), token0Bought);
        _approveToken(_ToWepoolToken1, address(weswapRouter), token1Bought);

        (uint256 amountA, uint256 amountB, uint256 LP) =
            weswapRouter.addLiquidity(
                _ToWepoolToken0,
                _ToWepoolToken1,
                token0Bought,
                token1Bought,
                1,
                1,
                address(this),
                deadline
            );

        if (transferResidual) {
            //Returning Residue in token0, if any.
            if (token0Bought - amountA > 0) {
                IERC20(_ToWepoolToken0).safeTransfer(
                    msg.sender,
                    token0Bought - amountA
                );
            }

            //Returning Residue in token1, if any
            if (token1Bought - amountB > 0) {
                IERC20(_ToWepoolToken1).safeTransfer(
                    msg.sender,
                    token1Bought - amountB
                );
            }
        }

        return LP;
    }

    function _fillQuote(
        address _fromTokenAddress,
        address _pairAddress,
        uint256 _amount,
        address _swapTarget,
        bytes memory swapData
    ) internal returns (uint256 amountBought, address intermediateToken) {
        if (_swapTarget == wwemixTokenAddress) {
            IWWEMIX(wwemixTokenAddress).deposit{ value: _amount }();
            return (_amount, wwemixTokenAddress);
        }

        uint256 valueToSend;
        if (_fromTokenAddress == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(_fromTokenAddress, _swapTarget, _amount);
        }

        (address _token0, address _token1) = _getPairTokens(_pairAddress);
        IERC20 token0 = IERC20(_token0);
        IERC20 token1 = IERC20(_token1);
        uint256 initialBalance0 = token0.balanceOf(address(this));
        uint256 initialBalance1 = token1.balanceOf(address(this));

        require(approvedTargets[_swapTarget], "Target not Authorized");
        (bool success, ) = _swapTarget.call{ value: valueToSend }(swapData);
        require(success, "Error Swapping Tokens 1");

        uint256 finalBalance0 =
            token0.balanceOf(address(this)) - initialBalance0;
        uint256 finalBalance1 =
            token1.balanceOf(address(this)) - initialBalance1;

        if (finalBalance0 > finalBalance1) {
            amountBought = finalBalance0;
            intermediateToken = _token0;
        } else {
            amountBought = finalBalance1;
            intermediateToken = _token1;
        }

        require(amountBought > 0, "Swapped to Invalid Intermediate");
    }

    function _swapIntermediate(
        address _swapFrom,
        address _ToWepoolToken0,
        address _ToWepoolToken1,
        uint256 _amount
    ) internal returns (uint256 token0Bought, uint256 token1Bought) {
        IWeswapPair pair =
            IWeswapPair(
                weswapFactory.getPair(
                    _ToWepoolToken0,
                    _ToWepoolToken1
                )
            );
        (uint256 res0, uint256 res1, ) = pair.getReserves();
        if (_swapFrom == _ToWepoolToken0) {
            uint256 amountToSwap = calculateSwapInAmount(res0, _amount);
            //if no reserve or a new pair is created
            if (amountToSwap <= 0) amountToSwap = _amount / 2;
            token1Bought = _token2Token(
                _swapFrom,
                _ToWepoolToken1,
                amountToSwap
            );
            token0Bought = _amount - amountToSwap;
        } else {
            uint256 amountToSwap = calculateSwapInAmount(res1, _amount);
            //if no reserve or a new pair is created
            if (amountToSwap <= 0) amountToSwap = _amount / 2;
            token0Bought = _token2Token(
                _swapFrom,
                _ToWepoolToken0,
                amountToSwap
            );
            token1Bought = _amount - amountToSwap;
        }
    }

    function calculateSwapInAmount(
        uint256 reserveIn,
        uint256 userIn
    ) internal pure returns (uint256) {
        // return (Math.sqrt(reserveIn * ((userIn * 3988000) + (reserveIn * 3988009))) - (reserveIn * 1997)) / 1994;

        // fee 0.0025
        // return (Math.sqrt(reserveIn * ((userIn * 399000000) + (reserveIn * 399000625))) - (reserveIn * 19975)) / 19950;
        return (Math.sqrt(reserveIn * ((userIn * 638400) + (reserveIn * 638401))) - (reserveIn * 799)) / 798;
    }

    /**
     * @notice This function is used to get amount to swap
     * @param _swapFrom The address of token swap from
     * @param _ToWepoolToken0 The token0 address
     * @param _ToWepoolToken1 The token1 address
     * @param _amount The amount of tokens to swap
     * @return amountToSwap Amount to swap
     */
    function getSwapInAmount(
        address _swapFrom,
        address _ToWepoolToken0,
        address _ToWepoolToken1,
        uint256 _amount
    ) external view returns (uint256 amountToSwap) {
        IWeswapPair pair = IWeswapPair(weswapFactory.getPair(_ToWepoolToken0, _ToWepoolToken1));
        (uint256 res0, uint256 res1, ) = pair.getReserves();
        if (_swapFrom == _ToWepoolToken0) {
            amountToSwap = calculateSwapInAmount(res0, _amount);
            if (amountToSwap <= 0) amountToSwap = _amount / 2;
        } else {
            amountToSwap = calculateSwapInAmount(res1, _amount);
            if (amountToSwap <= 0) amountToSwap = _amount / 2;
        }
    }

    function _partialSwapIntermediate(
        address _swapFrom,
        address _ToWepoolToken0,
        address _ToWepoolToken1,
        uint256 _amount0,
        uint256 _amount1
    ) internal returns (uint256 token0Bought, uint256 token1Bought) {
        IWeswapPair pair =
            IWeswapPair(
                weswapFactory.getPair(
                    _ToWepoolToken0,
                    _ToWepoolToken1
                )
            );
        (uint256 res0, uint256 res1, ) = pair.getReserves();
        if (_swapFrom == _ToWepoolToken0) {
            uint256 amountToSwap = calculatePartialSwapInAmount(
                res0, res1, _amount0, _amount1
            );
            //if no reserve or a new pair is created
            require(amountToSwap > 0, "ZapIn: not allowed to create pair");
            token1Bought = _token2Token(
                _swapFrom,
                _ToWepoolToken1,
                amountToSwap
            ) + _amount1;
            token0Bought = _amount0 - amountToSwap;
        } else {
            (_amount1, _amount0) = (_amount0, _amount1);
            uint256 amountToSwap = calculatePartialSwapInAmount(
                res1, res0, _amount1, _amount0
            );
            //if no reserve or a new pair is created
            require(amountToSwap > 0, "ZapIn: not allowed to create pair");
            token0Bought = _token2Token(
                _swapFrom,
                _ToWepoolToken0,
                amountToSwap
            ) + _amount0;
            token1Bought = _amount1 - amountToSwap;
        }
    }

    function calculatePartialSwapInAmount(
        uint256 reserveInA,
        uint256 reserveInB,
        uint256 userInA,
        uint256 userInB
    ) internal pure returns (uint256) {
        // return (Math.sqrt(reserveIn * ((userIn * 638400) + (reserveIn * 638401))) - (reserveIn * 799)) / 798;
        // return
        //     (
        //         Math.sqrt(
        //             reserveInA * (userInB + reserveInB) * ((638400 * userInA * reserveInB) + (reserveInA * userInB) + (638401 * reserveInA * reserveInB))
        //         ) - (799 * reserveInA * (userInB + reserveInB))
        //     ) / (798 * (userInB + reserveInB));

        uint256 denominator = 798 * (userInB + reserveInB);

        return (
            Math.sqrt(
                (
                    (reserveInA * (userInB + reserveInB) / denominator) * (
                        ((638400 * userInA * reserveInB) + (reserveInA * userInB) + (638401 * reserveInA * reserveInB)
                    ) / denominator)
                )
            ) - (799 * reserveInA * (userInB + reserveInB)) / denominator
        );
    }

    /**
     * @notice This function is used to get amount to swap
     * @param _swapFrom The address of token swap from
     * @param _ToWepoolToken0 The token0 address
     * @param _ToWepoolToken1 The token1 address
     * @param _amount0 The amount of token0 to swap
     * @param _amount1 The amount of token1 to swap
     * @return amountToSwap Amount to swap
     */
    function getPartialSwapInAmount(
        address _swapFrom,
        address _ToWepoolToken0,
        address _ToWepoolToken1,
        uint256 _amount0,
        uint256 _amount1
    ) external view returns (uint256 amountToSwap) {
        IWeswapPair pair = IWeswapPair(weswapFactory.getPair(_ToWepoolToken0, _ToWepoolToken1));
        (uint256 res0, uint256 res1, ) = pair.getReserves();
        if (_swapFrom == _ToWepoolToken0) {
            amountToSwap = calculatePartialSwapInAmount(res0, res1, _amount0, _amount1);
            require(amountToSwap > 0, "ZapIn: not allowed to create pair");
        } else {
            (_amount1, _amount0) = (_amount0, _amount1);
            amountToSwap = calculatePartialSwapInAmount(res1, res0, _amount1, _amount0);
            require(amountToSwap > 0, "ZapIn: not allowed to create pair");
        }
    }

    /**
    @notice This function is used to swap ERC20 <> ERC20
    @param _FromTokenContractAddress The token address to swap from.
    @param _ToTokenContractAddress The token address to swap to. 
    @param tokens2Trade The amount of tokens to swap
    @return tokenBought The quantity of tokens bought
     */
    function _token2Token(
        address _FromTokenContractAddress,
        address _ToTokenContractAddress,
        uint256 tokens2Trade
    ) internal returns (uint256 tokenBought) {
        if (_FromTokenContractAddress == _ToTokenContractAddress) {
            return tokens2Trade;
        }

        _approveToken(
            _FromTokenContractAddress,
            address(weswapRouter),
            tokens2Trade
        );

        address pair =
            weswapFactory.getPair(
                _FromTokenContractAddress,
                _ToTokenContractAddress
            );
        require(pair != address(0), "No Swap Available");
        address[] memory path = new address[](2);
        path[0] = _FromTokenContractAddress;
        path[1] = _ToTokenContractAddress;

        tokenBought = weswapRouter.swapExactTokensForTokens(
            tokens2Trade,
            1,
            path,
            address(this),
            deadline
        )[path.length - 1];

        require(tokenBought > 0, "Error Swapping Tokens 2");
    }
}
