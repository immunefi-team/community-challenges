//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/IERC223.sol";

contract Staking {
    IERC223 public token;
    address public owner;
    uint256 public reward;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public stakeDuration;
    mapping(address => bool) public rewardClaimed;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);

    constructor(address _token,uint256 _reward) payable {
        require(msg.value >= 100, "100 ETH required");
        owner = msg.sender;
        token = IERC223(_token);
        reward = _reward;
    }

    function balanceOf(address user) public view returns (uint256) {
        return balances[user];
    }

    function stake(uint256 amount) public {
        require(amount >= 10, "minimum is 10");
        token.transfer(address(this), amount);
        balances[msg.sender] += amount;
        stakeDuration[msg.sender] = block.timestamp;
        rewardClaimed[msg.sender] = false;
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) public {
        require(balances[msg.sender] >= amount, "user doesn't have enough deposited funds");
        uint256 stakedDiff = block.timestamp - stakeDuration[msg.sender];
        require(stakedDiff >= 604800,"wait till 7 days elapsed");
        if (!rewardClaimed[msg.sender]) {
            payable(msg.sender).transfer(reward); 
            rewardClaimed[msg.sender] = true;
        }
        token.transfer(msg.sender,amount);
        balances[msg.sender] -= amount;
        emit Unstaked(msg.sender, amount);
    }

}