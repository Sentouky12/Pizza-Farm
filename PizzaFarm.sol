// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

import "./RewardToken.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";



contract TheFarm {
 
address public owner;
  
  struct UserStakes {
    uint256 amount;   // How many tokens the user has staked
    uint256 reward;  
  }

  mapping (address => UserStakes) public userStakes;
 
  struct Farm {
    IERC20 token;
    uint256 startBlock;
    uint256 blockReward;
    uint256 endBlock;
    uint256 lastRewardBlock;  // Last block number that reward distribution occurs.
    uint256 accReward; // Accumulated Rewards per share
    uint256 farmableSupply; // total amount of tokens farmable
    uint256 nmFarmers;
    uint256 StakedTokens;
  }

  Farm public farm;

  event Deposit(address indexed user, uint256 amount);
  event Withdraw(address indexed user, uint256 amount);

  constructor(address _rewardToken, uint256 _amount, uint256 _blockReward,  uint256 _endBlock)  {
    owner=msg.sender;
    farm.token = IERC20(_rewardToken);
    farm.farmableSupply = _amount;
    farm.blockReward = _blockReward;
    farm.startBlock = block.number;
    farm.endBlock = _endBlock+block.number;
    farm.lastRewardBlock = block.number;
    farm.accReward = 0;
    farm.nmFarmers = 0;
    farm.StakedTokens = 0;
  }

 
  function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
      uint256 from = _from >= farm.startBlock ? _from : farm.startBlock;
      uint256 to = farm.endBlock > _to ? _to : farm.endBlock;
      return to-from;
  }




  function pendingReward(address _user) external view returns (uint256) {
    UserStakes storage user = userStakes[_user];
    uint256 accReward = farm.accReward;
    if (block.number > farm.lastRewardBlock && farm.StakedTokens != 0) {
      uint256 multiplier = getMultiplier(farm.lastRewardBlock, block.number);
      uint256 tokenReward = multiplier*farm.blockReward;
      accReward = accReward+tokenReward*1e18/farm.StakedTokens;
    }
    return user.amount*accReward/1e18-user.reward;
  }

 


  function updatePool() public {
    if (block.number <= farm.lastRewardBlock) {
      return;
    }
    if (farm.StakedTokens == 0) {
      farm.lastRewardBlock = block.number < farm.endBlock ? block.number : farm.endBlock;
      return;
    }
    uint256 multiplier = getMultiplier(farm.lastRewardBlock, block.number);
    uint256 tokenReward = multiplier*farm.blockReward;
    farm.accReward = farm.accReward+tokenReward*1e18/farm.StakedTokens;
    farm.lastRewardBlock = block.number < farm.endBlock ? block.number : farm.endBlock;
  }


  /**
   * @notice deposit token function for msg.sender
   * @param _amount the total deposit amount
   */
  function deposit(uint256 _amount) payable  public {
    UserStakes storage user = userStakes[msg.sender];
    updatePool();
    if (user.amount > 0) {
      uint256 pending = user.amount*farm.accReward/1e18-user.reward;
      safeTransfer(msg.sender, pending);
    }
    if (user.amount == 0 && _amount > 0) {
      farm.nmFarmers++;
    }
    require(farm.token.transferFrom(address(msg.sender), address(this), _amount), "Transfer failed");
    farm.StakedTokens = farm.StakedTokens+_amount;
    user.amount = user.amount+_amount;
    user.reward = user.amount*farm.accReward/1e18;
    emit Deposit(msg.sender, _amount);
  }
  
  /**
   * @notice withdraw token function for msg.sender
   * user will receive _amount plus rewards
   */ 
  function withdraw(uint256 _amount) public {
    UserStakes storage user = userStakes[msg.sender];
    require(user.amount >= _amount);
    updatePool();
    if (user.amount == _amount && _amount > 0) {
      farm.nmFarmers--;
    }
    uint256 pending = _amount+user.amount*farm.accReward/1e18-user.reward;
    safeTransfer(msg.sender, pending);
    farm.StakedTokens = farm.StakedTokens-_amount;
    user.amount = user.amount-_amount;
    user.reward = user.amount*farm.accReward/1e18;
    emit Withdraw(msg.sender, _amount);
  }

  /**
   * Safe reward transfer function, in case an error causes the pool to not have enough reward tokens
   * @param _to the user address to transfer tokens to
   * @param _amount the total amount of tokens to transfer
   */       
  function safeTransfer(address _to, uint256 _amount) internal {
    require(msg.sender == owner);
    uint256 FarmReward = farm.token.balanceOf(address(this));
    if (_amount > FarmReward) {
      farm.token.transfer(_to, FarmReward);
    } else {
      farm.token.transfer(_to, _amount);
    }
  }
}
