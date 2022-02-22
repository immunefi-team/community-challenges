//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Staking2 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    event Staked(address indexed staker, IERC20 indexed token, uint256 amount);
    event Claimed(address indexed staker, IERC20 indexed token, uint256 amount);
    event Unstaked(address indexed staker, IERC20 indexed token, uint256 amount);
    event Rewarded(address indexed funder, IERC20 indexed token, uint256 amount);

    struct StakerInfo {
        bool feeExempt;
        uint248 lastReward;
        uint256 staked;
    }

    struct TokenInfo {
        bool badlyBehaved;
        uint248 totalReward;
        mapping(address => StakerInfo) stakerInfo;
    }

    IERC20 public immutable REWARDS;
    uint256 public constant FEE_DENOM = 200;
    uint256 fees;
    mapping(IERC20 => TokenInfo) public tokenInfo;

    function stakerInfo(IERC20 token, address staker)
        external
        view
        returns (
            bool feeExempt,
            uint248 lastReward,
            uint256 staked
        )
    {
        StakerInfo storage _stakerInfo = tokenInfo[token].stakerInfo[staker];
        feeExempt = _stakerInfo.feeExempt;
        lastReward = _stakerInfo.lastReward;
        staked = _stakerInfo.staked;
    }

    constructor(IERC20 rewards) {
        REWARDS = rewards;
    }

    function reward(IERC20 token, address staker) public view returns (uint256 amount) {
        TokenInfo storage _tokenInfo = tokenInfo[token];
        StakerInfo storage _stakerInfo = _tokenInfo.stakerInfo[staker];
        uint256 balance = token.balanceOf(address(this));
        uint256 staked = _stakerInfo.staked;
        amount = _tokenInfo.totalReward - _stakerInfo.lastReward;
        if (balance != 0) {
            amount = (amount * staked) / balance;
        }
    }

    function sendReward(IERC20 token, address staker) public {
        require(token != REWARDS, "Staking2: reward token");
        TokenInfo storage _tokenInfo = tokenInfo[token];
        require(!_tokenInfo.badlyBehaved, "Staking2: badly-behaved token");
        uint256 amount = reward(token, staker);
        StakerInfo storage _stakerInfo = _tokenInfo.stakerInfo[staker];
        if (amount > 0) {
            if (!_stakerInfo.feeExempt) {
                uint256 fee = amount / FEE_DENOM;
                fees += fee;
                amount -= fee;
            }
            REWARDS.safeTransfer(staker, amount);
            emit Claimed(staker, token, amount);
        }
        _stakerInfo.lastReward = _tokenInfo.totalReward;
    }

    modifier poke(IERC20 token) {
        sendReward(token, _msgSender());
        _;
    }

    function _addStake(
        IERC20 token,
        address staker,
        uint256 amount
    ) internal {
        tokenInfo[token].stakerInfo[staker].staked += amount;
    }

    function _removeStake(
        IERC20 token,
        address staker,
        uint256 amount
    ) internal {
        tokenInfo[token].stakerInfo[staker].staked -= amount;
    }

    function stake(IERC20 token, uint256 amount) external nonReentrant poke(token) {
        uint256 balanceBefore = token.balanceOf(address(this));
        token.safeTransferFrom(_msgSender(), address(this), amount);
        amount = token.balanceOf(address(this)) - balanceBefore;
        _addStake(token, _msgSender(), amount);
        emit Staked(_msgSender(), token, amount);
    }

    function unstake(IERC20 token, uint256 amount) external nonReentrant poke(token) {
        uint256 balanceBefore = token.balanceOf(address(this));
        require(amount <= balanceBefore, "Staking2: unstake too much");
        TokenInfo storage _tokenInfo = tokenInfo[token];
        {
            // non-reverting `safeTransfer`
            (bool success, bytes memory returnData) = address(token).call(
                abi.encodeWithSelector(token.transfer.selector, _msgSender(), amount)
            );
            if (
                !success ||
                (
                    returnData.length >= 32
                        ? abi.decode(returnData, (bytes32)) != bytes32(uint256(1))
                        : returnData.length > 0
                )
            ) {
                _tokenInfo.badlyBehaved = true;
                return;
            }
        }
        amount = balanceBefore - token.balanceOf(address(this));
        emit Unstaked(_msgSender(), token, amount);
        _removeStake(token, _msgSender(), amount);
    }

    function addReward(IERC20 token, uint248 amount) external {
        tokenInfo[token].totalReward += amount;
        REWARDS.safeTransferFrom(_msgSender(), address(this), amount);
        emit Rewarded(_msgSender(), token, amount);
    }

    function setExempt(IERC20 token, address staker) external onlyOwner {
        tokenInfo[token].stakerInfo[staker].feeExempt = true;
    }

    function takeFee() external {
        uint256 _fees = fees;
        delete fees;
        REWARDS.safeTransfer(owner(), _fees);
    }
}
