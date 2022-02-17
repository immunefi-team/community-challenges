// SPDX-License-Identifier: unlicensed
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IMockERC721 is IERC721 {
    function mint() external returns (uint256);
}

contract Auction {
    IMockERC721 public nftContract;
    mapping(uint256 => address) public owner;
    mapping(uint256 => uint256) public period;
    uint256 private _lockStatus = 1;
    uint256 constant minBidAmount = 1 ether;

    struct Bid {
        address bidder;
        uint256 bid;
        bool status;
    }
    mapping(uint256 => Bid) public bidInfo;

    event ListedId(uint256 id, address owner);
    event TransferId(uint256 id, address from, address to);
    event BidId(uint256 id, address bidder, uint256 bidAmount);

    constructor(address _nftContract) {
        nftContract = IMockERC721(_nftContract);
    }

    modifier lock() {
        require(_lockStatus != 2, "Auction: reentrant call");
        _lockStatus = 2;
        _;
        _lockStatus = 1;
    }

    function list() external payable lock {
        require(msg.value == minBidAmount, "Auction: requires minBidAmount");
        uint256 id = nftContract.mint();
        owner[id] = msg.sender;
        period[id] = block.timestamp + 7 days;
        emit ListedId(id, msg.sender);
    }

    function bid(uint256 _id) external payable {
        require(owner[_id] != address(0), "Auction: not exist");
        require(owner[_id] != msg.sender, "Auction: owner not allowed to bid");
        require(period[_id] >= block.timestamp, "Auction: period over");
        require(msg.value > minBidAmount, "Auction: bid should be higher than minBidAmount");

        if (bidInfo[_id].status == true) {
            if (bidInfo[_id].bid < msg.value) {
                payable(bidInfo[_id].bidder).transfer(bidInfo[_id].bid);
                bidInfo[_id] = Bid({bidder: msg.sender, bid: msg.value, status: true});
            } else {
                revert("Auction: last bidder amount is greater");
            }
        } else {
            bidInfo[_id] = Bid({bidder: msg.sender, bid: msg.value, status: true});
        }

        emit BidId(_id, msg.sender, msg.value);
    }

    function collect(uint256 _id) external lock {
        require(owner[_id] != address(0), "Auction: not exist");
        require(period[_id] <= block.timestamp, "Auction: period is not over");
        require(bidInfo[_id].bidder == msg.sender, "Auction: only last bidder can collect");

        payable(owner[_id]).transfer(bidInfo[_id].bid);
        nftContract.safeTransferFrom(address(this), bidInfo[_id].bidder, _id);
        emit TransferId(_id, owner[_id], msg.sender);
    }
}
