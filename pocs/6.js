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

    let someHash = "0x0123456789012345678901234567890123456789012345678901234567890123";
    let someDescr = "I'm signing the message!";

    let payload = await ethers.utils.defaultAbiCoder.encode(["bytes32", "string"], [someHash, someDescr]);
    let payloadHash = await ethers.utils.keccak256(payload);

    let signature = await user1.signMessage(ethers.utils.arrayify(payloadHash));
    let splittedSig = ethers.utils.splitSignature(signature);
    await expect(await ethers.utils.verifyMessage(ethers.utils.arrayify(payloadHash), splittedSig)).to.equal(
        user1.address
    );

    await kyc.connect(user1).onboardWithSig(app1.address, someHash, someDescr, signature);
    await expect(await kyc.onboardedApps(app1.address)).to.equal(true);

    console.log("\nExploit POC : \n");
}

main();
