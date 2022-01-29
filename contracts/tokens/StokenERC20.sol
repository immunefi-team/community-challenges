//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";

contract StokenERC20 is IERC20 {
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    uint256 public override totalSupply;
    string public constant name = "STOKEN";
    string public constant symbol = "SETH";
    uint8 public constant decimals = 18;

    constructor(uint256 _totalSupply) {
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function transfer(address _to, uint256 _value) public override returns (bool) {
        if (balanceOf[msg.sender] >= _value && balanceOf[_to] + _value >= balanceOf[_to]) {
            balanceOf[msg.sender] -= _value;
            balanceOf[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override returns (bool) {
        if (
            balanceOf[_from] >= _value &&
            allowance[_from][msg.sender] >= _value &&
            balanceOf[_to] + _value >= balanceOf[_to]
        ) {
            balanceOf[_to] += _value;
            balanceOf[_from] -= _value;
            emit Transfer(_from, _to, _value);
            allowance[_from][msg.sender] -= _value;
            emit Approval(_from, msg.sender, allowance[_from][msg.sender]);
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint256 _value) public override returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}
