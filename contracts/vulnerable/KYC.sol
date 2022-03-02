// SPDX-License-Identifier: unlicenced
pragma solidity 0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";

interface IKYCApp {
    function owner() external returns (address);
}

contract KYC is Ownable {
    mapping(address => bool) public applicants;
    mapping(address => address) public whitelistedOwners;
    mapping(address => bool) public kycApplicants;

    function applyFor(address tokenAddr) external {
        require(tokenAddr != address(0), "KYC: token address must not be empty");
        require(IKYCApp(tokenAddr).owner() == msg.sender, "KYC: only owner of token can apply");
        applicants[tokenAddr] = true;
        whitelistedOwners[tokenAddr] = msg.sender;
    }

    function onboard(address tokenAddr) external {
        require(!kycApplicants[tokenAddr],"KYC: already onboarded");
        require(tokenAddr != address(0), "KYC: token address is zero");
        require(msg.sender == whitelistedOwners[tokenAddr], "KYC: only owner can onboard");
        kycApplicants[tokenAddr] = true;
    }

    function onboardWithSig(address tokenAddr,bytes32 msgHash,string memory description,bytes memory signature) external {
        require(!kycApplicants[tokenAddr],"KYC: already onboarded");
        require(tokenAddr != address(0), "KYC: token address is zero");
        bytes32 payloadHash = keccak256(abi.encode(msgHash, description));
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", payloadHash));
        _checkWhitelisted(tokenAddr, messageHash,signature);
        kycApplicants[tokenAddr] = true;
    }

    function _checkWhitelisted(address _tokenAddr,bytes32 _messageHash,bytes memory _signature) internal view {
        address signer = recoverSigner(_messageHash,_signature);
        require(signer == whitelistedOwners[_tokenAddr], "KYC: only owner can onboard");
    }

    function recoverSigner(bytes32 hash, bytes memory signature) internal pure returns(address) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;

            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            address recovered = ecrecover(hash, v, r, s);
            return recovered;

        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
        
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }

            bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
            uint8 v = uint8((uint256(vs) >> 255) + 27);

            address recovered = ecrecover(hash, v, r, s);
            return recovered;
        }
        else {
            revert("Signature is not valid");
        }
    }
}
