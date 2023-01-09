## `WeswapZapOut`






### `constructor(address _router, address _wwemix, uint256 _goodwill, uint256 _affiliateSplit)` (public)





### `ZapOut2PairToken(address fromPoolAddress, uint256 incomingLP, address affiliate) → uint256 amountA, uint256 amountB` (public)

Zap out in both tokens




### `ZapOutUnproportionate2PairToken(address toTokenAddress, address fromPoolAddress, uint256 incomingLP, uint256 amountToSwap, uint256 minToken0Rec, uint256 minToken1Rec, address[] swapTargets, bytes[] swapData, address affiliate, bool shouldSellEntireBalance) → uint256 token0Rec, uint256 token1Rec` (public)

Zap out in tokens unproportionately




### `ZapOutUnproportionate2PairTokenWithPermit(address toTokenAddress, address fromPoolAddress, uint256 incomingLP, uint256 amountToSwap, uint256 minToken0Rec, uint256 minToken1Rec, bytes permitSig, address[] swapTargets, bytes[] swapData, address affiliate) → uint256 token0Rec, uint256 token1Rec` (external)

Zap out in tokens unproportionately




### `ZapOut(address toTokenAddress, address fromPoolAddress, uint256 incomingLP, uint256 minTokensRec, address[] swapTargets, bytes[] swapData, address affiliate, bool shouldSellEntireBalance) → uint256 tokensRec` (public)

Zap out in a single token




### `_swapTokensSimple(address fromPoolAddress, uint256 amount0, uint256 amount1, address toToken, address[] path, function (uint256,uint256,address[],address,uint256) external returns (uint256[]) swapFunc) → uint256 tokensBought` (internal)





### `ZapOutSimple(address toTokenAddress, address fromPoolAddress, uint256 incomingLP, address[] path, uint256 minTokensRec, address affiliate, bool shouldSellEntireBalance) → uint256 tokensRec` (external)

Zap out in a single token (token0-token1 pair always exist)




### `ZapOut2PairTokenWithPermit(address fromPoolAddress, uint256 incomingLP, address affiliate, bytes permitSig) → uint256 amountA, uint256 amountB` (external)

Zap out in both tokens with permit




### `ZapOutWithPermit(address toTokenAddress, address fromPoolAddress, uint256 incomingLP, uint256 minTokensRec, bytes permitSig, address[] swapTargets, bytes[] swapData, address affiliate) → uint256` (external)

Zap out in a single token with permit




### `_permit(address fromPoolAddress, uint256 amountIn, bytes permitSig)` (internal)





### `_removeLiquidity(address fromPoolAddress, uint256 incomingLP, bool shouldSellEntireBalance) → uint256 amount0, uint256 amount1` (internal)





### `_swapTokens(address fromPoolAddress, uint256 amount0, uint256 amount1, address toToken, address[] swapTargets, bytes[] swapData) → uint256 tokensBought` (internal)





### `_partialSwapTokens(address fromPoolAddress, uint256 amount0, uint256 amount1, address toToken, uint256 amountToSwap, address[] swapTargets, bytes[] swapData) → uint256 token0Bought, uint256 token1Bought` (internal)





### `_fillQuote(address fromTokenAddress, address toToken, uint256 amount, address swapTarget, bytes swapData) → uint256` (internal)





### `removeLiquidityReturn(address fromPoolAddress, uint256 liquidity) → uint256 amountA, uint256 amountB, address token0, address token1` (external)

Utility function to determine quantity and addresses of tokens being removed





