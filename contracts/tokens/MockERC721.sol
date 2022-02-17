// SPDX-License-Identifier: unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockERC721 is ERC721 {
    uint256 public nftId;

    constructor() ERC721("MockERC721", "INFT") {}

    function mint() external returns (uint256) {
        _mint(msg.sender, nftId);
        uint256 currentId = nftId;
        nftId++;
        return currentId;
    }
}