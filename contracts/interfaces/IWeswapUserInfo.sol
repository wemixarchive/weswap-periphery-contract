// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

interface IWeswapUserInfo {
    struct UserInfo {
        uint256 reserve0;
        uint256 reserve1;
        uint256 wen; // WEN MOON SIR?
    }

    function pair() external view returns (address);

    function updateUserInfo(address account_) external;

    function getUserInfo(address account_)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    event User(
        address indexed user,
        uint256 reserve0,
        uint256 reserve1,
        uint256 wen
    );

    event Pair(address indexed pair);
}
