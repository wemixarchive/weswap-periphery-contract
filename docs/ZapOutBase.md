## `ZapOutBase`






### `_pullTokens(address token, uint256 amount, bool shouldSellEntireBalance) → uint256` (internal)



Transfer tokens from msg.sender to this contract
        @param token The ERC20 token to transfer to this contract
        @param shouldSellEntireBalance If True transfers entrire allowable amount from another contract
        @return Quantity of tokens transferred to this contract

### `_subtractGoodwill(address token, uint256 amount, address affiliate, bool enableGoodwill) → uint256 totalGoodwillPortion` (internal)






