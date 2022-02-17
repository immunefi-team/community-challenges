//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Takeover {
    address public owner;
    mapping(address => uint256) public deposits;
    event OwnershipChanged(address indexed _old, address indexed _new);

    constructor() payable {
        require(msg.value >= 10 ether, "Takeover: Minimum ETH required");
        owner = msg.sender;
        emit OwnershipChanged(address(0), owner);
    }

    modifier onlyAuth() {
        require(msg.sender == owner || msg.sender == address(this), "Takeover: not allowed");
        _;
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    function changeOwner(address newOwner) external onlyAuth {
        require(newOwner != address(0), "Takeover: no address(0)");
        require(newOwner != owner, "Takeover: no current owner");
        emit OwnershipChanged(owner, newOwner);
        owner = newOwner;
    }

    function staticall(
        address target,
        bytes memory payload,
        string memory errorMessage
    ) external returns (bytes memory) {
        require(isContract(target), "Takeover: call to non-contract");
        (bool success, bytes memory returnData) = address(target).call(payload);
        return verifyCallResult(success, returnData, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function deposit() public payable {
        require(msg.value == 1 ether, "Takeover: You can only send 1 Ether");
        deposits[msg.sender] += 1;
    }

    function withdraw() public {
        deposits[msg.sender] -= 1;
        (bool sent, ) = msg.sender.call{value: 1 ether}("");
        require(sent, "Takeover: Failed to send Ether");
    }

    function withdrawAll() external {
        require(msg.sender == owner, "Takeover: only owner can withdraw");
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Takeover: Failed to send Ether");
    }
}
