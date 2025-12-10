// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockRouter {
    // Simple mock: pull tokens from caller (contract that approved us) and forward to `to`.
    function addLiquidity(
        address tokenA,
        address tokenB,
        bool,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256,
        uint256,
        address to,
        uint256
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        if (amountADesired > 0) {
            require(IERC20(tokenA).transferFrom(msg.sender, to, amountADesired), "transferFrom A failed");
        }
        if (amountBDesired > 0) {
            require(IERC20(tokenB).transferFrom(msg.sender, to, amountBDesired), "transferFrom B failed");
        }
        amountA = amountADesired;
        amountB = amountBDesired;
        liquidity = amountA + amountB;
    }
}
