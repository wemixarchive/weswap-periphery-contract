## `IWeswapZapOut`






### `ZapOut2PairToken(address fromPoolAddress, uint256 incomingLP, address affiliate) → uint256 amountA, uint256 amountB` (external)

Zap out in both tokens




### `ZapOutUnproportionate2PairToken(address toTokenAddress, address fromPoolAddress, uint256 incomingLP, uint256 amountToSwap, uint256 minToken0Rec, uint256 minToken1Rec, address[] swapTargets, bytes[] swapData, address affiliate, bool shouldSellEntireBalance) → uint256 token0Rec, uint256 token1Rec` (external)

Zap out in tokens unproportionately




### `ZapOutUnproportionate2PairTokenWithPermit(address toTokenAddress, address fromPoolAddress, uint256 incomingLP, uint256 amountToSwap, uint256 minToken0Rec, uint256 minToken1Rec, bytes permitSig, address[] swapTargets, bytes[] swapData, address affiliate) → uint256 token0Rec, uint256 token1Rec` (external)

Zap out in tokens unproportionately




### `ZapOut(address toTokenAddress, address fromPoolAddress, uint256 incomingLP, uint256 minTokensRec, address[] swapTargets, bytes[] swapData, address affiliate, bool shouldSellEntireBalance) → uint256 tokensRec` (external)

Zap out in a single token




### `ZapOutSimple(address toTokenAddress, address fromPoolAddress, uint256 incomingLP, address[] path, uint256 minTokensRec, address affiliate, bool shouldSellEntireBalance) → uint256 tokensRec` (external)

Zap out in a single token (token0-token1 pair always exist)




### `ZapOut2PairTokenWithPermit(address fromPoolAddress, uint256 incomingLP, address affiliate, bytes permitSig) → uint256 amountA, uint256 amountB` (external)

Zap out in both tokens with permit




### `ZapOutWithPermit(address toTokenAddress, address fromPoolAddress, uint256 incomingLP, uint256 minTokensRec, bytes permitSig, address[] swapTargets, bytes[] swapData, address affiliate) → uint256` (external)

Zap out in a single token with permit




### `removeLiquidityReturn(address fromPoolAddress, uint256 liquidity) → uint256 amountA, uint256 amountB, address token0, address token1` (external)

Utility function to determine quantity and addresses of tokens being removed





### `zapOut(address sender, address pool, address token, uint256 tokensRec)`





