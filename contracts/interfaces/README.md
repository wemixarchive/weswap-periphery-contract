# IWeswapRouter

> Referred to [uniswap docs](https://docs.uniswap.org/protocol/V2/reference/smart-contracts/router-02)

## TL;DR

### Add Liquidity

> `addLiquidity`: Adds liquidity to an ERC-20⇄ERC-20 pool.

> `addLiquidityWEMIX`: Adds liquidity to an ERC-20⇄WWEMIX pool with WEMIX.

Inputs

* `token`: the address of pool token
* `~Desired`: amount of token/WEMIX to add as liquidity
* `~Min`: lower bounds of token/WEMIX that must be sent
* `to`: recipient of LP token
* `deadline`: transaction expiration

Outputs

* `amount`: the amount of token/WEMIX sent to the pool
* `liquidity`: LP token amount

### Remove Liquidity

> `removeLiquidity`: Removes liquidity from an ERC-20⇄WWEMIX pool and receive WEMIX.

> `removeLiquidityWEMIX`: Removes liquidity from an ERC-20⇄WWEMIX pool and receive WEMIX.

Inputs

* `token`: the address of pool token
* `liquidity`: LP token amount
* `~Min`: lower bounds of token/WEMIX that must be received
* `to`: recipient of underlying token/WEMIX
* `deadline`: transaction expiration

Outputs

* `amount`: the amount of token/WEMIX received

### Swap

> `swapExactTokensForTokens`: Swaps an exact amount of input tokens for as many output tokens as possible.

> `swapTokensForExactTokens`: Receive an exact amount of output tokens for as few input tokens as possible.

> `swapExactWEMIXForTokens`: Swaps an exact amount of WEMIX for as many output tokens as possible.

> `swapTokensForExactWEMIX`: Receive an exact amount of WEMIX for as few input tokens as possible.

> `swapExactTokensForWEMIX`: Swaps an exact amount of tokens for as much WEMIX as possible.

> `swapWEMIXForExactTokens`: Receive an exact amount of tokens for as little WEMIX as possible.

Inputs

* `amountOut`: the amount of output token/WEMIX to receive.
* `amountOutMin`: the minimum amount of output token/WEMIX that must be received
* `amountInMax`: the maximum amount of input token/WEMIX.
* `path`: swap path; from --> (path) --> to; path.length must be >= 2
* `to`: recipient of output token/WEMIX
* `deadline`: transaction expiration

Outputs

* `amounts`: the input token/WEMIX amount and all subsequent output token/WEMIX amounts

## Read-Only Functions

### factory

```solidity
function factory() external pure returns (address);
```

Returns factory address.

### WWEMIX

```solidity
function WWEMIX() external view returns (address);
```

Returns the canonical WWEMIX address on the Wemix blockchain.

### quote

```solidity
function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);
```

Given some asset amount and reserves, returns an amount of the other asset representing equivalent value.

Useful for calculating optimal token amounts before calling mint.

### getAmountOut

```solidity
function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountOut);
```

Given an input asset amount, returns the maximum output amount of the other asset (accounting for fees) given reserves.

Used in getAmountsOut.

### getAmountIn

```solidity
function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256 amountIn);
```

Returns the minimum input asset amount required to buy the given output asset amount (accounting for fees) given reserves.

Used in getAmountsIn.

### getAmountsOut

```solidity
function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
```

Given an input asset amount and an array of token addresses, calculates all subsequent maximum output token amounts by calling getReserves for each pair of token addresses in the path in turn, and using these to call getAmountOut.

Useful for calculating optimal token amounts before calling swap.

### getAmountsIn

```solidity
function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
```

Given an output asset amount and an array of token addresses, calculates all preceding minimum input token amounts by calling getReserves for each pair of token addresses in the path in turn, and using these to call getAmountIn.

Useful for calculating optimal token amounts before calling swap.

## State-Changing Functions

### addLiquidity

```solidity
function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
```

Adds liquidity to an ERC-20⇄ERC-20 pool.

* To cover all possible scenarios, msg.sender should have already given the router an allowance of at least amountADesired/amountBDesired on tokenA/tokenB.
* Always adds assets at the ideal ratio, according to the price when the transaction is executed.
* If a pool for the passed tokens does not exists, one is *not* created automatically.

| Name | Type | | 
|---|---|---|
| tokenA | address | A pool token. |
| tokenB | address | A pool token. |
| amountADesired | uint | The amount of tokenA to add as liquidity if the B/A price is <= amountBDesired/amountADesired (A depreciates). |
| amountBDesired | uint | The amount of tokenB to add as liquidity if the A/B price is <= amountADesired/amountBDesired (B depreciates). |
| amountAMin | uint | Bounds the extent to which the B/A price can go up before the transaction reverts. Must be <= amountADesired. |
| amountBMin | uint | Bounds the extent to which the A/B price can go up before the transaction reverts. Must be <= amountBDesired. |
| to | address | Recipient of the liquidity tokens. |
| deadline | uint | Unix timestamp after which the transaction will revert. |
| amountA | uint | The amount of tokenA sent to the pool. |
| amountB | uint | The amount of tokenB sent to the pool. |
| liquidity | uint | The amount of liquidity tokens minted. |

### addLiquidityWEMIX

```solidity
function addLiquidityWEMIX(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountWEMIXMin,
    address to,
    uint256 deadline
) external payable returns (uint256 amountToken, uint256 amountWEMIX, uint256 liquidity);
```

Adds liquidity to an ERC-20⇄WWEMIX pool with WEMIX.

* To cover all possible scenarios, msg.sender should have already given the router an allowance of at least amountTokenDesired on token.
* Always adds assets at the ideal ratio, according to the price when the transaction is executed.
* msg.value is treated as a amountWEMIXDesired.
* Leftover WEMIX, if any, is returned to msg.sender.
* If a pool for the passed token and WWEMIX does not exists, one is *not* created automatically.

| Name | Type | | 
|---|---|---|
| token | address | A pool token. | 
| amountTokenDesired | uint | The amount of token to add as liquidity if the WWEMIX/token price is <= msg.value/amountTokenDesired (token depreciates). |
| msg.value (amountWEMIXDesired) | uint | The amount of WEMIX to add as liquidity if the token/WWEMIX price is <= amountTokenDesired/msg.value (WWEMIX depreciates). |
| amountTokenMin | uint | Bounds the extent to which the WWEMIX/token price can go up before the transaction reverts. Must be <= amountTokenDesired. |
| amountWEMIXMin | uint | Bounds the extent to which the token/WWEMIX price can go up before the transaction reverts. Must be <= msg.value. | 
| to | address | Recipient of the liquidity tokens. | 
| deadline | uint | Unix timestamp after which the transaction will revert. | 
| amountToken | uint | The amount of token sent to the pool. | 
| amountWEMIX | uint | The amount of WEMIX converted to WWEMIX and sent to the pool. | 
| liquidity | uint | The amount of liquidity tokens minted. | 

### removeLiquidity

```solidity
function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
) external returns (uint256 amountA, uint256 amountB);
```

Removes liquidity from an ERC-20⇄ERC-20 pool.

msg.sender should have already given the router an allowance of at least liquidity on the pool.

| Name | Type | | 
|---|---|---|
| tokenA | address | A pool token. |
| tokenB | address | A pool token. |
| liquidity | uint | The amount of liquidity tokens to remove. |
| amountAMin | uint | The minimum amount of tokenA that must be received for the transaction not to revert. |
| amountBMin | uint | The minimum amount of tokenB that must be received for the transaction not to revert. |
| to | address | Recipient of the underlying assets. |
| deadline | uint | Unix timestamp after which the transaction will revert. |
| amountA | uint | The amount of tokenA received. |
| amountB | uint | The amount of tokenB received. |

### removeLiquidityWEMIX

```solidity
function removeLiquidityWEMIX(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountWEMIXMin,
    address to,
    uint256 deadline
) external returns (uint256 amountToken, uint256 amountWEMIX);
```

Removes liquidity from an ERC-20⇄WWEMIX pool and receive WEMIX.

msg.sender should have already given the router an allowance of at least liquidity on the pool.

| Name | Type | | 
|---|---|---|
| token | address | A pool token. |
| liquidity | uint | The amount of liquidity tokens to remove. |
| amountTokenMin | uint | The minimum amount of token that must be received for the transaction not to revert. |
| amountWEMIXMin | uint | The minimum amount of WEMIX that must be received for the transaction not to revert. |
| to | address | Recipient of the underlying assets. |
| deadline | uint | Unix timestamp after which the transaction will revert. |
| amountToken | uint | The amount of token received. |
| amountWEMIX | uint | The amount of WEMIX received. |

### removeLiquidityWithPermit

TBD

### removeLiquidityWEMIXWithPermit

TBD

### swapExactTokensForTokens

```solidity
function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
) external returns (uint256[] memory amounts);
```

Swaps an exact amount of input tokens for as many output tokens as possible, along the route determined by the path. The first element of path is the input token, the last is the output token, and any intermediate elements represent intermediate pairs to trade through (if, for example, a direct pair does not exist).

msg.sender should have already given the router an allowance of at least amountIn on the input token.

| Name | Type | | 
|---|---|---|
| amountIn | uint | The amount of input tokens to send. |
| amountOutMin | uint | The minimum amount of output tokens that must be received for the transaction not to revert. |
| path | address[] calldata | An array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity. |
| to | address | Recipient of the output tokens. |
| deadline | uint | Unix timestamp after which the transaction will revert. |
| amounts | uint[] memory | The input token amount and all subsequent output token amounts. |

### swapTokensForExactTokens

```solidity
function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
) external returns (uint256[] memory amounts);
```

Receive an exact amount of output tokens for as few input tokens as possible, along the route determined by the path. The first element of path is the input token, the last is the output token, and any intermediate elements represent intermediate tokens to trade through (if, for example, a direct pair does not exist).

msg.sender should have already given the router an allowance of at least amountInMax on the input token.
| Name | Type | | 
|---|---|---|
| amountOut | uint | The amount of output tokens to receive. |
| amountInMax | uint | The maximum amount of input tokens that can be required before the transaction reverts. |
| path | address[] calldata | An array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity. |
| to | address | Recipient of the output tokens. |
| deadline | uint | Unix timestamp after which the transaction will revert. |
| amounts | uint[] memory | The input token amount and all subsequent output token amounts. |

### swapExactWEMIXForTokens

```solidity
function swapExactWEMIXForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
    external
    payable
    returns (uint256[] memory amounts);
```

Swaps an exact amount of WEMIX for as many output tokens as possible, along the route determined by the path. The first element of path must be WWEMIX, the last is the output token, and any intermediate elements represent intermediate pairs to trade through (if, for example, a direct pair does not exist).

| Name | Type | | 
|---|---|---|
| msg.value (amountIn) | uint | The amount of WEMIX to send. |
| amountOutMin | uint | The minimum amount of output tokens that must be received for the transaction not to revert. |
| path | address[] calldata | An array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity. |
| to | address | Recipient of the output tokens. |
| deadline | uint | Unix timestamp after which the transaction will revert. |
| amounts | uint[] memory | The input token amount and all subsequent output token amounts. |

### swapTokensForExactWEMIX

```solidity
function swapTokensForExactWEMIX(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline)
    external
    returns (uint256[] memory amounts);
```

Receive an exact amount of WEMIX for as few input tokens as possible, along the route determined by the path. The first element of path is the input token, the last must be WWEMIX, and any intermediate elements represent intermediate pairs to trade through (if, for example, a direct pair does not exist).

msg.sender should have already given the router an allowance of at least amountInMax on the input token.
If the to address is a smart contract, it must have the ability to receive WEMIX.

| Name | Type | | 
|---|---|---|
| amountOut | uint | The amount of WEMIX to receive. |
| amountInMax | uint | The maximum amount of input tokens that can be required before the transaction reverts. |
| path | address[] calldata | An array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity. |
| to | address | Recipient of WEMIX. |
| deadline | uint | Unix timestamp after which the transaction will revert. |
| amounts | uint[] memory | The input token amount and all subsequent output token amounts. |

### swapExactTokensForWEMIX

```solidity
function swapExactTokensForWEMIX(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
    external
    returns (uint256[] memory amounts);
```

Swaps an exact amount of tokens for as much WEMIX as possible, along the route determined by the path. The first element of path is the input token, the last must be WWEMIX, and any intermediate elements represent intermediate pairs to trade through (if, for example, a direct pair does not exist).

If the to address is a smart contract, it must have the ability to receive WEMIX.

| Name | Type | | 
|---|---|---|
| amountIn | uint | The amount of input tokens to send. |
| amountOutMin | uint | The minimum amount of output tokens that must be received for the transaction not to revert. |
| path | address[] calldata | An array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity. |
| to | address | Recipient of the WEMIX. |
| deadline | uint | Unix timestamp after which the transaction will revert. |
| amounts | uint[] memory | The input token amount and all subsequent output token amounts. |

### swapWEMIXForExactTokens

```solidity
function swapWEMIXForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline)
    external
    payable
    returns (uint256[] memory amounts);
```

Receive an exact amount of tokens for as little WEMIX as possible, along the route determined by the path. The first element of path must be WWEMIX, the last is the output token and any intermediate elements represent intermediate pairs to trade through (if, for example, a direct pair does not exist).

Leftover WEMIX, if any, is returned to msg.sender.

| Name | Type | | 
|---|---|---|
| amountOut | uint | The amount of tokens to receive. |
| msg.value (amountInMax) | uint | The maximum amount of WEMIX that can be required before the transaction reverts. |
| path | address[] calldata | An array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity. |
| to | address | Recipient of the output tokens. |
| deadline | uint | Unix timestamp after which the transaction will revert. |
| amounts | uint[] memory | The input token amount and all subsequent output token amounts. |
