// SPDX-License-Identifier: unlicenced
pragma solidity 0.8.4;

contract KYCApp {
    address public owner;

    constructor() {
        owner = msg.sender;
    }
}
