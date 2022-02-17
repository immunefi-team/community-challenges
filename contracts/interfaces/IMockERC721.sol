// SPDX-License-Identifier: unlicensed
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IMockERC721 is IERC721 {
    function mint() external returns (uint256);
}
