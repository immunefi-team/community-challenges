// SPDX-License-Identifier: unlicenced
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IKYCApp {
    function owner() external returns (address);
}

contract KYC is Ownable, Pausable {
    mapping(address => bool) public applicants;
    mapping(address => address) public whitelistedOwners;
    mapping(address => bool) public kycApplicants;

    string public constant EIP712_DOMAIN =
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,address tokenAddr)";

    bytes32 public constant EIP712_DOMAIN_TYPEHASH = keccak256(abi.encodePacked(EIP712_DOMAIN));

    function domainSeparator(address tokenAddr) public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    keccak256("KYC"),
                    keccak256("1"),
                    block.chainid,
                    address(this),
                    address(tokenAddr)
                )
            );
    }

    function hashMessage(address tokenAddr, bytes32 message) public view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator(tokenAddr), message));
    }

    function applyFor(address tokenAddr) external whenNotPaused {
        require(tokenAddr != address(0), "KYC: token address must not be empty");
        require(IKYCApp(tokenAddr).owner() == msg.sender, "KYC: only owner of token can apply");
        applicants[tokenAddr] = true;
        whitelistedOwners[tokenAddr] = msg.sender;
    }

    function onboard(address tokenAddr) external {
        require(tokenAddr != address(0), "KYC: token address must not be empty");
        require(msg.sender == whitelistedOwners[tokenAddr], "KYC: only owner can onboard");
        kycApplicants[tokenAddr] = true;
    }

    function onboardWithSig(
        address tokenAddr,
        bytes32 data,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external whenNotPaused {
        require(tokenAddr != address(0), "KYC: token address must not be empty");
        bytes32 hashMsg = hashMessage(tokenAddr, data);
        _checkWhitelisted(tokenAddr, hashMsg, v, r, s);
        kycApplicants[tokenAddr] = true;
    }

    function _checkWhitelisted(
        address _tokenAddr,
        bytes32 _hashMsg,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view {
        address recoverSigner = ecrecover(_hashMsg, v, r, s);
        require(recoverSigner == whitelistedOwners[_tokenAddr], "KYC: only owner can onboard");
    }
}
