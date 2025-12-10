// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract EUSD is ERC20 {
    address public creator;
    uint256 public initialFeeBps; // in basis points (e.g., 200 = 2%)
    uint256 public skimFeeBps;    // in basis points (e.g., 50 = 0.5%)

    constructor(
        string memory name_,
        string memory symbol_,
        address creator_,
        uint256 supply_,
        uint256 initialFeeBps_,
        uint256 skimFeeBps_
    ) ERC20(name_, symbol_) {
        creator = creator_;
        initialFeeBps = initialFeeBps_;
        skimFeeBps = skimFeeBps_;
        
        // Calculate initial fee
        uint256 feeAmount = (supply_ * initialFeeBps_) / 10000;
        uint256 remaining = supply_ - feeAmount;
        
        // Mint fee portion to creator
        if (feeAmount > 0) {
            _mint(creator_, feeAmount);
        }
        
        // Mint remaining to msg.sender (the factory/deployer)
        if (remaining > 0) {
            _mint(msg.sender, remaining);
        }
    }
}

