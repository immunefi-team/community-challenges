//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* 
    Contract takes ERC20 Stokens as input
    and returns the native ETH (1:1 ratio).
*/

contract Exchange {
    IERC20 public token;
    address public owner;
    mapping(address => uint256) private balances;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event NativeTransfer(address indexed to, uint256 amount);

    constructor(address _token) payable {
        require(msg.value >= 100, "100 ETH required");
        owner = msg.sender;
        token = IERC20(_token);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function changeToken(address _newToken) public onlyOwner {
        token = IERC20(_newToken);
    }

    function balanceOf(address user) public view returns (uint256) {
        return balances[user];
    }

    function enter(uint256 amount) public {
        require(amount >= 10, "minimum is 10");
        token.transferFrom(msg.sender, address(this), amount);
        balances[msg.sender] += amount;
        emit Transfer(msg.sender, address(this), amount);
    }

    function exit(uint256 amount) public {
        uint256 getAmount = balances[msg.sender];
        require(getAmount >= amount, "user doesn't have enough funds deposited");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit NativeTransfer(msg.sender, amount);
    }
}
