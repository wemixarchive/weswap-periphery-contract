## `WeswapZapIn`






### `constructor(address _factory, address _router, address _wwemix, uint256 _goodwill, uint256 _affiliateSplit)` (public)





### `ZapInUnproportionate2PairToken(address _FromTokenAContractAddress, address _FromTokenBContractAddress, address _pairAddress, uint256 _amountA, uint256 _amountB, uint256 _minPoolTokens, address _swapTarget, bytes swapData, bool transferResidual, bool shouldSellEntireBalance) → uint256` (external)

This function is used to invest in given Weswap pair through WEMIX/ERC20 Tokens;
tokenA should be valuable than tokenB (swap a into b)




### `ZapIn(address _FromTokenContractAddress, address _pairAddress, uint256 _amount, uint256 _minPoolTokens, address _swapTarget, bytes swapData, address affiliate, bool transferResidual, bool shouldSellEntireBalance) → uint256` (external)

This function is used to invest in given Weswap pair through WEMIX/ERC20 Tokens




### `_getPairTokens(address _pairAddress) → address token0, address token1` (internal)





### `_performZapIn(address _FromTokenContractAddress, address _pairAddress, uint256 _amount, address _swapTarget, bytes swapData, bool transferResidual) → uint256` (internal)





### `_performZapInUnproportionate2PairToken(address _FromTokenAContractAddress, address _FromTokenBContractAddress, address _pairAddress, uint256 _amountA, uint256 _amountB, address _swapTarget, bytes swapData, bool transferResidual) → uint256` (internal)





### `_weDeposit(address _ToWepoolToken0, address _ToWepoolToken1, uint256 token0Bought, uint256 token1Bought, bool transferResidual) → uint256` (internal)





### `_fillQuote(address _fromTokenAddress, address _pairAddress, uint256 _amount, address _swapTarget, bytes swapData) → uint256 amountBought, address intermediateToken` (internal)





### `_swapIntermediate(address _swapFrom, address _ToWepoolToken0, address _ToWepoolToken1, uint256 _amount) → uint256 token0Bought, uint256 token1Bought` (internal)





### `calculateSwapInAmount(uint256 reserveIn, uint256 userIn) → uint256` (internal)





### `getSwapInAmount(address _swapFrom, address _ToWepoolToken0, address _ToWepoolToken1, uint256 _amount) → uint256 amountToSwap` (external)

This function is used to get amount to swap




### `_partialSwapIntermediate(address _swapFrom, address _ToWepoolToken0, address _ToWepoolToken1, uint256 _amount0, uint256 _amount1) → uint256 token0Bought, uint256 token1Bought` (internal)





### `calculatePartialSwapInAmount(uint256 reserveInA, uint256 reserveInB, uint256 userInA, uint256 userInB) → uint256` (internal)





### `getPartialSwapInAmount(address _swapFrom, address _ToWepoolToken0, address _ToWepoolToken1, uint256 _amount0, uint256 _amount1) → uint256 amountToSwap` (external)

This function is used to get amount to swap




### `_token2Token(address _FromTokenContractAddress, address _ToTokenContractAddress, uint256 tokens2Trade) → uint256 tokenBought` (internal)

This function is used to swap ERC20 <> ERC20
    @param _FromTokenContractAddress The token address to swap from.
    @param _ToTokenContractAddress The token address to swap to. 
    @param tokens2Trade The amount of tokens to swap
    @return tokenBought The quantity of tokens bought




