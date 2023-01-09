// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

interface IWeswapZapIn {
    event zapIn(address sender, address pool, uint256 tokensRec);

    /**
     * @notice This function is used to invest in given Weswap pair through WEMIX/ERC20 Tokens;
     * tokenA should be valuable than tokenB (swap a into b)
     * @param _FromTokenAContractAddress The ERC20 token used for investment (address(0x00) if WEMIX)
     * @param _FromTokenBContractAddress The ERC20 token used for investment (address(0x00) if WEMIX)
     * @param _pairAddress The Weswap pair address
     * @param _amountA The amount of fromToken to invest
     * @param _amountB The amount of fromToken to invest
     * @param _minPoolTokens Reverts if less tokens received than this
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
    ) external payable returns (uint256);

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
    ) external payable returns (uint256);
}
