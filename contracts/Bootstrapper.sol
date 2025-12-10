// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IAerodromeRouter.sol";

/**
 * @dev Minimal bootstrap helper for pair ensure + addLiquidity.
 * This is a stub demonstrating flow; production should validate pairs/factory.
 */
contract Bootstrapper {
    address public router;
    address public creator;
    uint256 public skimFeeBps; // 50 = 0.5%

    event Withdraw(address indexed token, address indexed to, uint256 amount);
    event SkimFeeUpdated(uint256 oldBps, uint256 newBps);

    constructor(address router_, address creator_, uint256 skimFeeBps_) {
        router = router_;
        creator = creator_;
        skimFeeBps = skimFeeBps_;
    }

    modifier onlyCreator() {
        require(msg.sender == creator, "only creator");
        _;
    }

    /**
     * Caller must approve this contract to pull `amountADesired`/`amountBDesired` before calling.
     * The contract will take the full desired amounts, transfer the skim portion to `creator`,
     * and use the net amounts to provide liquidity via the router.
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        // Pull tokens from caller into this contract
        if (amountADesired > 0) {
            require(IERC20(tokenA).transferFrom(msg.sender, address(this), amountADesired), "transferA failed");
        }
        if (amountBDesired > 0) {
            require(IERC20(tokenB).transferFrom(msg.sender, address(this), amountBDesired), "transferB failed");
        }


        // Calculate skim fees and transfer to creator, then use net amounts
        uint256 skimA = (amountADesired * skimFeeBps) / 10000;
        if (skimA > 0) {
            require(IERC20(tokenA).transfer(creator, skimA), "skimA transfer failed");
        }
        uint256 skimB = (amountBDesired * skimFeeBps) / 10000;
        if (skimB > 0) {
            require(IERC20(tokenB).transfer(creator, skimB), "skimB transfer failed");
        }

        // Approve router to pull net amounts (compute inline to reduce locals)
        if (amountADesired > skimA) {
            require(IERC20(tokenA).approve(router, amountADesired - skimA), "approveA failed");
        }
        if (amountBDesired > skimB) {
            require(IERC20(tokenB).approve(router, amountBDesired - skimB), "approveB failed");
        }

        // Call router to add liquidity using net amounts
        (amountA, amountB, liquidity) = IAerodromeRouter(router).addLiquidity(
            tokenA, tokenB, stable,
            amountADesired - skimA, amountBDesired - skimB,
            amountAMin, amountBMin,
            to, block.timestamp + 1200
        );

        // Any leftover tokens remain in the contract (caller can withdraw later) — this is a minimal implementation.
    }

    /**
     * @dev Withdraw `amount` of ERC20 `token` from this contract to `to`.
     * Can only be called by `creator`.
     */
    function withdrawERC20(address token, uint256 amount, address to) external onlyCreator {
        require(IERC20(token).transfer(to, amount), "withdraw failed");
        emit Withdraw(token, to, amount);
    }

    /**
     * @dev Emergency withdraw full balance of `token` to `creator`.
     */
    function emergencyWithdraw(address token) external onlyCreator {
        uint256 bal = IERC20(token).balanceOf(address(this));
        if (bal > 0) {
            require(IERC20(token).transfer(creator, bal), "emergency withdraw failed");
            emit Withdraw(token, creator, bal);
        }
    }

    /**
     * @dev Update skim fee (bps). Only creator may call.
     */
    function setSkimFeeBps(uint256 newBps) external onlyCreator {
        uint256 old = skimFeeBps;
        skimFeeBps = newBps;
        emit SkimFeeUpdated(old, newBps);
    }
}
