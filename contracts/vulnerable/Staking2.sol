//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Staking2 is Context, ReentrancyGuard {
    using SafeERC20 for IERC20;

    event Staked(address indexed staker, IERC20 indexed token, uint256 amount);
    event Claimed(address indexed staker, IERC20 indexed token, uint256 amount);
    event Unstaked(address indexed staker, IERC20 indexed token, uint256 amount);
    event Rewarded(address indexed funder, IERC20 indexed token, uint256 amount);

    struct TokenInfo {
        bool badlyBehaved;
        uint120 depositCount;
        uint120 withdrawCount;
    }

    IERC20 public immutable REWARDS;
    mapping(IERC20 => uint256) public totalReward;
    mapping(IERC20 => mapping(address => uint256)) public stakedAmount;
    mapping(IERC20 => mapping(address => uint256)) public rewardDebt;
    mapping(IERC20 => TokenInfo) public tokenInfo;

    constructor(IERC20 rewards) {
        REWARDS = rewards;
    }

    function _reward(
        uint256 amount,
        uint256 balance,
        IERC20 token,
        address staker
    ) internal view returns (uint256) {
        return (amount * totalReward[token]) / balance - rewardDebt[token][staker];
    }

    function _reward(
        uint256 balance,
        IERC20 token,
        address staker
    ) internal view returns (uint256) {
        return _reward(stakedAmount[token][staker], balance, token, staker);
    }

    function reward(IERC20 token, address staker) public view returns (uint256) {
        return _reward(token.balanceOf(address(this)), token, staker);
    }

    modifier goodToken(IERC20 token) {
        require(token != REWARDS, "Staking2: can't stake reward token");
        require(!tokenInfo[token].badlyBehaved, "Staking2: can't stake badly-behaved token");
        _;
    }

    function stake(IERC20 token, uint256 amount) external goodToken(token) {
        uint256 balanceBefore = token.balanceOf(address(this));
        uint256 rewardBefore = _reward(balanceBefore, token, _msgSender());
        token.safeTransferFrom(_msgSender(), address(this), amount);
        uint256 balanceAfter = token.balanceOf(address(this));
        amount = balanceAfter - balanceBefore;
        stakedAmount[token][_msgSender()] += amount;
        tokenInfo[token].depositCount += 1;
        uint256 rewardAfter = _reward(balanceAfter, token, _msgSender());
        rewardDebt[token][_msgSender()] += rewardAfter - rewardBefore;
        emit Staked(_msgSender(), token, amount);
    }

    function claim(IERC20 token) external nonReentrant goodToken(token) {
        uint256 amount = reward(token, _msgSender());
        rewardDebt[token][_msgSender()] += amount;
        REWARDS.safeTransfer(_msgSender(), amount);
        emit Claimed(_msgSender(), token, amount);
    }

    function unstake(IERC20 token, uint256 amount) external nonReentrant goodToken(token) {
        uint256 balanceBefore = token.balanceOf(address(this));
        uint256 rewardBefore = _reward(balanceBefore, token, _msgSender());
        require(amount <= balanceBefore, "Staking2: unstake too much");
        tokenInfo[token].withdrawCount += 1;
        {
            (bool success, bytes memory returnData) = address(token).call(
                abi.encodeWithSelector(token.transfer.selector, _msgSender(), amount)
            );
            if (
                !success ||
                (returnData.length >= 32 && abi.decode(returnData, (bytes32)) != bytes32(uint256(1))) ||
                returnData.length > 0
            ) {
                tokenInfo[token].badlyBehaved = true;
                return;
            }
        }
        uint256 balanceAfter = token.balanceOf(address(this));
        amount = balanceBefore - balanceAfter;
        stakedAmount[token][_msgSender()] -= amount;
        emit Unstaked(_msgSender(), token, amount);
        uint256 rewardAmount = rewardBefore - _reward(balanceAfter, token, _msgSender());
        if (rewardAmount != 0) {
            rewardDebt[token][_msgSender()] -= rewardAmount;
            REWARDS.safeTransfer(_msgSender(), rewardAmount);
            emit Claimed(_msgSender(), token, rewardAmount);
        }
    }

    function addReward(IERC20 token, uint256 amount) external goodToken(token) {
        totalReward[token] += amount;
        REWARDS.safeTransferFrom(_msgSender(), address(this), amount);
        emit Rewarded(_msgSender(), token, amount);
    }
}
