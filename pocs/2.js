const { expect } = require("chai");
const { ethers } = require("hardhat");

const ONE_ETHER = ethers.utils.parseUnits("1", "ether");
const FIFTY_ETHER = ethers.utils.parseUnits("50", "ether");
const REWARD_AMOUNT = ethers.utils.parseUnits("0.1","ether");

async function deploy(deployer) {
    let deployTokens = ethers.utils.parseUnits("1000", "ether");

    // Deploy ERC223 token
    const mockERC223 = await ethers.getContractFactory("MockERC223", deployer);
    const mtoken = await mockERC223.deploy(deployTokens);
    await expect(await mtoken.connect(deployer).balanceOf(deployer.address)).to.equal(deployTokens);

    // Deploy Staking contract
    const Staking = await ethers.getContractFactory("Staking", deployer);
    const staking = await Staking.deploy(mtoken.address, REWARD_AMOUNT, { value: FIFTY_ETHER.mul(5) });
    await expect(await staking.token()).to.equal(mtoken.address);
    await expect(await ethers.provider.getBalance(staking.address)).to.equal(FIFTY_ETHER.mul(5));

    return [mtoken, staking];
}


async function main() {
    console.log("CHALLENGE - 2\n")
    let [deployer, user1, user2] = await ethers.getSigners();
    let [mtoken, staking] = await deploy(deployer);

    console.log("ERC223 token :", mtoken.address);
    console.log("STAKING contract :", staking.address);

    await mtoken.name();
    await mtoken.connect(deployer)["transfer(address,uint256)"](user1.address,FIFTY_ETHER);
    await mtoken.connect(deployer)["transfer(address,uint256)"](user2.address,FIFTY_ETHER);

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
