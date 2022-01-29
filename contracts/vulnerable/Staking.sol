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

    constructor(address _token, uint256 _reward) payable {
        require(msg.value >= 100, "100 ETH required");
        owner = msg.sender;
        token = IERC223(_token);
        reward = _reward;
    }

    function balanceOf(address user) public view returns (uint256) {
        return balances[user];
    }

    function _stake(address user, uint256 amount) internal {
        balances[user] += amount;
        stakeDuration[user] = block.timestamp;
        rewardClaimed[user] = false;
        emit Staked(user, amount);
    }

    function unstake(uint256 amount) public {
        uint256 userBal = balances[msg.sender];
        require(userBal >= amount, "Staking: user doesn't have enough deposited funds");
        uint256 stakedDiff = block.timestamp - stakeDuration[msg.sender];
        require(stakedDiff >= 604800, "Staking: wait till 7 days elapsed");
        if (!rewardClaimed[msg.sender]) {
            payable(msg.sender).send(reward);
            rewardClaimed[msg.sender] = true;
        }
        token.transfer(msg.sender, amount);
        balances[msg.sender] = userBal - amount;
        emit Unstaked(msg.sender, amount);
    }

    function tokenReceived(
        address _from,
        uint256 _amount,
        bytes memory _data
    ) public {
        require(msg.sender == address(token), "Staking: Call only allowed from ERC223 token");
        require(_amount > 0, "Staking: Non-zero");
        _stake(_from, _amount);
    }
}
