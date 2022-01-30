// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Use only for testing purposes

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IERC677.sol";
import "../interfaces/IERC677TransferReceiver.sol";

contract ERC677 is IERC677, ERC20 {
    constructor(
        address initialAccount,
        uint256 initialBalance,
        string memory tokenName,
        string memory tokenSymbol
    ) ERC20(tokenName, tokenSymbol) {
        _mint(initialAccount, initialBalance);
    }

    /**
     * ERC-677's only method implementation
     * See https://github.com/ethereum/EIPs/issues/677 for details
     */
    function transferAndCall(
        address to,
        uint256 value,
        bytes memory data
    ) external override returns (bool) {
        bool result = super.transfer(to, value);
        if (!result) return false;

        emit Transfer(msg.sender, to, value, data);

        // IMPORTANT: the ERC-677 specification does not say anything about the
        // use of the receiver contract's tokenFallback method return
        // value. Given its return type matches with this method's return type,
        // returning it could be a possibility. Here we take the more
        // conservative approach and decode the return value if it's present,
        // otherwise we assume no revert signals a succesful transfer.
        bytes memory returnData;
        (result, returnData) = to.call(
            abi.encodeWithSelector(IERC677TransferReceiver.tokenFallback.selector, msg.sender, value, data)
        );
        require(
            result && (returnData.length == 0 || abi.decode(returnData, (bool))),
            "ERC677: transfer to non ERC677Receiver implementer"
        );

        return true;
    }
}
