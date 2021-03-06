// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract RewardToken is ERC20 {
 
  string constant NAME    = "Pizza";
  string constant SYMBOL  = "PZZ";
  uint8 constant DECIMALS = 18;
  uint256 constant INITIAL_SUPPLY = 10000000*10**uint256(DECIMALS);

  constructor()  ERC20(NAME, SYMBOL) {
    _mint(msg.sender, INITIAL_SUPPLY);
  }
}
