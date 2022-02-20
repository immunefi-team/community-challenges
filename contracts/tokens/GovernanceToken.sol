//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {MockERC20} from "./MockERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract GovernanceToken is MockERC20, Ownable {
    mapping(address => bool) isBlacklisted;
    mapping(address => address) delegateOf;
    mapping(address => uint256) delegatedTokens;

    constructor(uint256 _totalSupply) MockERC20(_totalSupply) {
        delegatedTokens[delegateOf[_msgSender()]] += _totalSupply;
    }

    modifier syncDelegates(address account) {
        delegatedTokens[delegateOf[account]] -= balanceOf[account];
        _;
        delegatedTokens[delegateOf[account]] += balanceOf[account];
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override syncDelegates(sender) syncDelegates(recipient) {
        require(
            !isBlacklisted[sender] && !isBlacklisted[recipient] && !isBlacklisted[_msgSender()],
            "BlacklistableToken: blacklisted"
        );
        super._transfer(sender, recipient, amount);
    }

    function delegate(address newDelegate) external syncDelegates(_msgSender()) {
        delegateOf[_msgSender()] = newDelegate;
    }

    function setBlacklist(address account, bool blacklisted) external onlyOwner {
        isBlacklisted[account] = blacklisted;
    }
}
