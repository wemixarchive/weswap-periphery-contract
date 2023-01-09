// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

// WEMIXAddress: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE

abstract contract ZapBase is Ownable {
    using SafeERC20 for IERC20;
    bool public stopped = false;

    // if true, goodwill is not deducted
    mapping(address => bool) public feeWhitelist;

    uint256 public goodwill;
    // % share of goodwill (0-100 %)
    uint256 affiliateSplit;
    // restrict affiliates
    mapping(address => bool) public affiliates;
    // affiliate => token => amount
    mapping(address => mapping(address => uint256)) public affiliateBalance;
    // token => amount
    mapping(address => uint256) public totalAffiliateBalance;
    // swapTarget => approval status
    mapping(address => bool) public approvedTargets;

    address internal constant WEMIXAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    event AddWhitelist(address account);
    event RemoveWhitelist(address account);
    
    event SetGoodwill(uint256 value);
    event SetAffiliateSplit(uint256 value);

    event AddAffiliate(address account);
    event RemoveAffiliate(address account);

    event WithdrawTokens(address[] tokens);

    event AddApproveTarget(address account);
    event RemoveApproveTarget(address account);

    event Receive(address indexed who, uint256 value);

    constructor(uint256 _goodwill, uint256 _affiliateSplit) {
        goodwill = _goodwill;
        affiliateSplit = _affiliateSplit;
    }

    // circuit breaker modifiers
    modifier stopInEmergency {
        if (stopped) {
            revert("Temporarily Paused");
        } else {
            _;
        }
    }

    function _getBalance(address token)
        internal
        view
        returns (uint256 balance)
    {
        if (token == address(0)) {
            balance = address(this).balance;
        } else {
            balance = IERC20(token).balanceOf(address(this));
        }
    }

    function _approveToken(address token, address spender) internal {
        IERC20 _token = IERC20(token);
        if (_token.allowance(address(this), spender) > 0) return;
        else {
            _token.safeApprove(spender, type(uint256).max);
        }
    }

    function _approveToken(
        address token,
        address spender,
        uint256 amount
    ) internal {
        IERC20(token).safeApprove(spender, 0);
        IERC20(token).safeApprove(spender, amount);
    }

    // - to Pause the contract
    function toggleContractActive() external onlyOwner {
        stopped = !stopped;
        emit Paused(msg.sender);
    }

    function set_feeWhitelist(address zapAddress, bool status)
        external
        onlyOwner
    {
        feeWhitelist[zapAddress] = status;
        if (status) { emit AddWhitelist(zapAddress); }
        else { emit RemoveWhitelist(zapAddress); }
    }

    function set_new_goodwill(uint256 _new_goodwill) external onlyOwner {
        require(
            _new_goodwill >= 0 && _new_goodwill <= 100,
            "GoodWill Value not allowed"
        );
        goodwill = _new_goodwill;
        emit SetGoodwill(_new_goodwill);
    }

    function set_new_affiliateSplit(uint256 _new_affiliateSplit)
        external
        onlyOwner
    {
        require(
            _new_affiliateSplit <= 100,
            "Affiliate Split Value not allowed"
        );
        affiliateSplit = _new_affiliateSplit;
        emit SetAffiliateSplit(_new_affiliateSplit);
    }

    function set_affiliate(address _affiliate, bool _status)
        external
        onlyOwner
    {
        affiliates[_affiliate] = _status;
        if (_status) { emit AddAffiliate(_affiliate); }
        else { emit RemoveAffiliate(_affiliate); }
    }

    ///@notice Withdraw goodwill share, retaining affilliate share
    function withdrawTokens(address[] calldata tokens) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 qty;

            if (tokens[i] == WEMIXAddress) {
                qty = address(this).balance - totalAffiliateBalance[tokens[i]];

                Address.sendValue(payable(owner()), qty);
            } else {
                qty =
                    IERC20(tokens[i]).balanceOf(address(this)) -
                    totalAffiliateBalance[tokens[i]];
                IERC20(tokens[i]).safeTransfer(owner(), qty);
            }
        }

        emit WithdrawTokens(tokens);
    }

    ///@notice Withdraw affilliate share, retaining goodwill share
    function affilliateWithdraw(address[] calldata tokens) external {
        uint256 tokenBal;
        for (uint256 i = 0; i < tokens.length; i++) {
            tokenBal = affiliateBalance[msg.sender][tokens[i]];
            affiliateBalance[msg.sender][tokens[i]] = 0;
            totalAffiliateBalance[tokens[i]] =
                totalAffiliateBalance[tokens[i]] -
                tokenBal;

            if (tokens[i] == WEMIXAddress) {
                Address.sendValue(payable(msg.sender), tokenBal);
            } else {
                IERC20(tokens[i]).safeTransfer(msg.sender, tokenBal);
            }
        }
    }

    function setApprovedTargets(
        address[] calldata targets,
        bool[] calldata isApproved
    ) external onlyOwner {
        require(targets.length == isApproved.length, "Invalid Input length");

        for (uint256 i = 0; i < targets.length; i++) {
            approvedTargets[targets[i]] = isApproved[i];

            if (isApproved[i]) { emit AddApproveTarget(targets[i]); }
            else { emit RemoveApproveTarget(targets[i]); }
        }
    }

    receive() external payable {
        require(msg.sender != tx.origin, "Do not send WEMIX directly");
        emit Receive(msg.sender, msg.value);
    }
}

abstract contract ZapInBase is ZapBase {
    using SafeERC20 for IERC20;

    function _pullTokens(
        address token,
        uint256 amount,
        address affiliate,
        bool enableGoodwill,
        bool shouldSellEntireBalance
    ) internal returns (uint256 value) {
        uint256 totalGoodwillPortion;

        if (token == address(0)) {
            require(msg.value > 0, "No WEMIX sent");

            // subtract goodwill
            totalGoodwillPortion = _subtractGoodwill(
                WEMIXAddress,
                msg.value,
                affiliate,
                enableGoodwill
            );

            return msg.value - totalGoodwillPortion;
        }
        require(amount > 0, "Invalid token amount");
        // require(msg.value == 0, "WEMIX sent with token");

        //transfer token
        if (shouldSellEntireBalance) {
            require(
                Address.isContract(msg.sender) && (msg.sender != tx.origin),
                "ERR: shouldSellEntireBalance is true for EOA"
            );
            amount = IERC20(token).allowance(msg.sender, address(this));
        }
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // subtract goodwill
        totalGoodwillPortion = _subtractGoodwill(
            token,
            amount,
            affiliate,
            enableGoodwill
        );

        return amount - totalGoodwillPortion;
    }

    function _subtractGoodwill(
        address token,
        uint256 amount,
        address affiliate,
        bool enableGoodwill
    ) internal returns (uint256 totalGoodwillPortion) {
        bool whitelisted = feeWhitelist[msg.sender];
        if (enableGoodwill && !whitelisted && goodwill > 0) {
            totalGoodwillPortion = (amount * goodwill) / 10000;

            if (affiliates[affiliate]) {
                if (token == address(0)) {
                    token = WEMIXAddress;
                }

                uint256 affiliatePortion =
                    (totalGoodwillPortion * affiliateSplit) / 100;
                affiliateBalance[affiliate][token] =
                    affiliateBalance[affiliate][token] +
                    affiliatePortion;
                totalAffiliateBalance[token] =
                    totalAffiliateBalance[token] +
                    affiliatePortion;
            }
        }
    }
}

abstract contract ZapOutBase is ZapBase {
    using SafeERC20 for IERC20;

    /**
        @dev Transfer tokens from msg.sender to this contract
        @param token The ERC20 token to transfer to this contract
        @param shouldSellEntireBalance If True transfers entrire allowable amount from another contract
        @return Quantity of tokens transferred to this contract
     */
    function _pullTokens(
        address token,
        uint256 amount,
        bool shouldSellEntireBalance
    ) internal returns (uint256) {
        if (shouldSellEntireBalance) {
            require(
                Address.isContract(msg.sender) && (msg.sender != tx.origin),
                "ERR: shouldSellEntireBalance is true for EOA"
            );

            uint256 allowance =
                IERC20(token).allowance(msg.sender, address(this));
            IERC20(token).safeTransferFrom(
                msg.sender,
                address(this),
                allowance
            );

            return allowance;
        } else {
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

            return amount;
        }
    }

    function _subtractGoodwill(
        address token,
        uint256 amount,
        address affiliate,
        bool enableGoodwill
    ) internal returns (uint256 totalGoodwillPortion) {
        bool whitelisted = feeWhitelist[msg.sender];
        if (enableGoodwill && !whitelisted && goodwill > 0) {
            totalGoodwillPortion = (amount * goodwill) / 10000;

            if (affiliates[affiliate]) {
                if (token == address(0)) {
                    token = WEMIXAddress;
                }

                uint256 affiliatePortion =
                    (totalGoodwillPortion * affiliateSplit) / 100;
                affiliateBalance[affiliate][token] += affiliatePortion;
                totalAffiliateBalance[token] += affiliatePortion;
            }
        }
    }
}
