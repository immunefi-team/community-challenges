// SPDX-License-Identifier: unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";

contract MockERC777 is ERC777 {
    constructor(uint256 _initialSupply) ERC777("MockERC777", "MTK7", new address[](0)) {
        _mint(_msgSender(), _initialSupply, "", "");
    }
}
