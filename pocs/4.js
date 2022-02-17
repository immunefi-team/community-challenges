const { expect } = require("chai");
const { ethers } = require("hardhat");
const { blockchainNow, setBlockchainTime, parseEth } = require("./utils/helpers.js");

async function deploy(deployer) {
    const Mock721 = await ethers.getContractFactory("MockERC721", deployer);
    const mock721 = await Mock721.deploy();

    const Auction = await ethers.getContractFactory("Auction", deployer);
    const auction = await Auction.deploy(mock721.address);

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

    // POC

    tokenId++;
    console.log("\n EXPLOIT : \n");
}

main();
