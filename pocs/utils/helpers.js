"use strict";

const { ethers } = require("hardhat");

async function blockchainNow() {
    return (await ethers.provider.getBlock("latest")).timestamp;
}

async function blockForwarder(targetBlock) {
    while ((await ethers.provider.getBlockNumber()) != targetBlock) {
        await network.provider.send("evm_mine");
    }
}

async function setBlockchainTime(newTime, mine) {
    if (typeof mine === "undefined") {
        mine = true;
    }
    await ethers.provider.send("evm_setNextBlockTimestamp", [newTime]);
    if (mine) {
        await ethers.provider.send("evm_mine", []);
    }
}

module.exports = { setBlockchainTime, blockchainNow, blockForwarder };
