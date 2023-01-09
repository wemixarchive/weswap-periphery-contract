## `IWeswapPair`






### `MINIMUM_LIQUIDITY() → uint256` (external)





### `factory() → address` (external)





### `token0() → address` (external)





### `token1() → address` (external)





### `getReserves() → uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast` (external)





### `price0CumulativeLast() → uint256` (external)





### `price1CumulativeLast() → uint256` (external)





### `kLast() → uint256` (external)





### `mint(address to) → uint256 liquidity` (external)





### `burn(address to) → uint256 amount0, uint256 amount1` (external)





### `swap(uint256 amount0Out, uint256 amount1Out, address to, bytes data)` (external)





### `skim(address to)` (external)





### `sync()` (external)





### `initialize(address, address)` (external)





### `pause()` (external)





### `unpause()` (external)





### `paused() → bool` (external)





### `userInfoContract() → address` (external)





### `updateUserInfoContract(address newUserInfoContract)` (external)





### `disableUserInfoContract()` (external)





### `userInfo(address user) → uint256, uint256, uint256` (external)






### `Mint(address sender, uint256 amount0, uint256 amount1)`





### `Burn(address sender, uint256 amount0, uint256 amount1, address to)`





### `Swap(address sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address to)`





### `Sync(uint112 reserve0, uint112 reserve1)`





### `Initialize(address token0, address token1, address factory)`





### `UpdateUsers(address prev, address curr)`





