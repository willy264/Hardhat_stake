// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Stake {

  struct StakeStruct {
    uint256 amount;
    uint256 startTime;
    uint256 rewardAccumulated;
  }

  // state variables
    address public owner;
    IERC20 public token;
    uint256 public totalStaked;
    uint256 public stakeRewards; // rewards per stake(token)
    uint256 public stakeDuration;  // minimum stake duration 
    mapping(address => StakeStruct) public stakers;



    event Staked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    
    constructor( address _token, uint256 _stakeDuration ) {
      stakeDuration = _stakeDuration;
      token = IERC20(_token);
      owner = msg.sender;
    }

    // Custom errors
    error ZeroAmount();
    error InsufficientStake();
    error MinimumStakePeriodNotReached();
    error NoRewardsToClaim();

    // functions
    function stake(uint256 _amount) external {
      if (_amount == 0) revert ZeroAmount();

      token.transferFrom(msg.sender, address(this),  _amount);
  
      StakeStruct storage user = stakers[msg.sender]; 
      user.amount += _amount;

      if (user.startTime == 0){  // checking if the user is staking for the first time
        user.startTime = block.timestamp;
      }
      totalStaked += _amount;

      emit Staked(msg.sender, _amount);
    }

    function withdrawStake(uint256 _amount) external {
      StakeStruct storage user = stakers[msg.sender];
      if (_amount == 0) revert ZeroAmount();
      if (_amount > totalStaked) revert InsufficientStake();
      if (block.timestamp < stakeDuration) revert MinimumStakePeriodNotReached();

      token.transfer(msg.sender, _amount);
      user.amount -= _amount;
      totalStaked -= _amount;
    }
    
    function claimRewards() external {
      StakeStruct storage user = stakers[msg.sender];
      uint256 rewards = calculateRewards(msg.sender) + user.rewardAccumulated;
      if (rewards == 0) revert NoRewardsToClaim();

      token.transfer(msg.sender, rewards);
      user.rewardAccumulated = 0;
      user.startTime = block.timestamp; 

      emit RewardClaimed(msg.sender, rewards);
    }

    function calculateRewards(address _staker) public view returns (uint256) {
      StakeStruct storage user = stakers[_staker];
      uint256 timeStaked = block.timestamp - user.startTime;
      return (user.amount * stakeDuration * timeStaked) / 1e18;
    }
}