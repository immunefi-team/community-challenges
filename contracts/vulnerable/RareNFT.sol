//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../tokens/MockERC721.sol";

contract RareNFT is Ownable, ReentrancyGuard {
    MockERC721 immutable nftContract;
    uint256 public nftPrice = 1 ether;
    uint256 private nonce;

    struct Token {
        address owner;
        uint256 value;
        bool rare;
    }
    mapping(uint256 => Token) public tokenInfo;
    mapping(address => bool) public minted;
    mapping(address => bool) public collected;

    event NFTcontract(address nft);
    event PriceChanged(uint256 oldPrice, uint256 newPrice);
    event Minted(uint256 id, address owner);
    event Collected(uint256 id, address owner);

    constructor() payable {
        require(msg.value >= 1 ether, "RareNFT: requires 1 ether");
        MockERC721 _nftContract = new MockERC721();
        nftContract = _nftContract;
        emit NFTcontract(address(_nftContract));
    }

    function changePrice(uint256 newPrice) external onlyOwner {
        require(newPrice > 0,"RareNFT: new price must be greater than 0");
        emit PriceChanged(nftPrice, newPrice);
        nftPrice = newPrice;
    }

    function _randGenerator(uint256 _drawNum) internal returns (uint256) {
        require(_drawNum > 0, "RareNFT: drawNum must be greater than 0");
        bytes32 randHash = keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, block.coinbase, gasleft(), tx.gasprice, tx.origin, nonce, msg.sender));
        uint256 random = uint256(randHash)% _drawNum;
        nonce++;
        return random;
    }

    function mint(uint256 drawNum) external payable nonReentrant {
        require(!minted[msg.sender],"RareNFT: you have already minted");
        require(msg.value == nftPrice, "RareNFT: requires mint amount");
        uint256 id = nftContract.mint();
        uint256 lucky = _randGenerator(drawNum);
        if (lucky == 4) {
            tokenInfo[id] = Token({owner: msg.sender, value: nftPrice, rare: true});
        } else {
            tokenInfo[id] = Token({owner: msg.sender, value: nftPrice, rare: false});
        }
        minted[msg.sender] = true;
        emit Minted(id, msg.sender);
    }

    function collect(uint256 id) external payable nonReentrant {
       require(!collected[msg.sender],"RareNFT: you have already collected");
       Token memory tk  = tokenInfo[id];
       require(tk.owner == msg.sender,"RareNFT: id doesn't belongs to you");
       if (tk.rare) {
           payable(msg.sender).transfer(0.1 ether);
        }
        nftContract.safeTransferFrom(address(this), msg.sender, id);
        collected[msg.sender] = true;
        emit Collected(id,msg.sender);
    }
}