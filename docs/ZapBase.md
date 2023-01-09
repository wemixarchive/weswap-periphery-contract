## `ZapBase`





### `stopInEmergency()`






### `constructor(uint256 _goodwill, uint256 _affiliateSplit)` (internal)





### `_getBalance(address token) → uint256 balance` (internal)





### `_approveToken(address token, address spender)` (internal)





### `_approveToken(address token, address spender, uint256 amount)` (internal)





### `toggleContractActive()` (external)





### `set_feeWhitelist(address zapAddress, bool status)` (external)





### `set_new_goodwill(uint256 _new_goodwill)` (external)





### `set_new_affiliateSplit(uint256 _new_affiliateSplit)` (external)





### `set_affiliate(address _affiliate, bool _status)` (external)





### `withdrawTokens(address[] tokens)` (external)

Withdraw goodwill share, retaining affilliate share



### `affilliateWithdraw(address[] tokens)` (external)

Withdraw affilliate share, retaining goodwill share



### `setApprovedTargets(address[] targets, bool[] isApproved)` (external)





### `receive()` (external)






### `Paused(address account)`



Emitted when the pause is triggered by `account`.

### `Unpaused(address account)`



Emitted when the pause is lifted by `account`.

### `AddWhitelist(address account)`





### `RemoveWhitelist(address account)`





### `SetGoodwill(uint256 value)`





### `SetAffiliateSplit(uint256 value)`





### `AddAffiliate(address account)`





### `RemoveAffiliate(address account)`





### `WithdrawTokens(address[] tokens)`





### `AddApproveTarget(address account)`





### `RemoveApproveTarget(address account)`





### `Receive(address who, uint256 value)`





