// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

interface IWeswapZapOut {
    event zapOut(address sender, address pool, address token, uint256 tokensRec);

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
    ) external returns (uint256 amountA, uint256 amountB);

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
    ) external returns (uint256 token0Rec, uint256 token1Rec);

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
    ) external returns (uint256 token0Rec, uint256 token1Rec);

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
    ) external returns (uint256 tokensRec);

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
    ) external returns (uint256 tokensRec);

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
    ) external returns (uint256 amountA, uint256 amountB);

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
    ) external returns (uint256);

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
    ) external view returns (uint256 amountA, uint256 amountB, address token0, address token1);
}
