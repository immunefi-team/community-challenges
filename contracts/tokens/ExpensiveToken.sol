//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {MockERC20} from "./MockERC20.sol";

contract ExpensiveToken is MockERC20 {
    uint256[] internal expensiveArray;

    constructor(uint256 _totalSupply) MockERC20(_totalSupply) {
        for (uint256 i; i < 512; i++) {
            expensiveArray.push(i);
        }
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        super._transfer(sender, recipient, amount);
        for (uint256 i; i < expensiveArray.length; i++) {
            expensiveArray[i];
        }
    }
}
