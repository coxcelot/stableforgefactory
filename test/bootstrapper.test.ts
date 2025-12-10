import { expect } from "chai";
import { ethers } from "hardhat";

// --- ABI Definitions ---
// Minimal ABI for ERC20 contract (USDC)
const IERC20_ABI = [
  "function approve(address spender, uint256 amount) returns (bool)",
  "function balanceOf(address account) returns (uint256)",
  "function transfer(address to, uint256 amount) returns (bool)",
  "function transferFrom(address from, address to, uint256 amount) returns (bool)",
];

// Minimal ABI for Aerodrome Router
const IAERODROME_ROUTER_ABI = [
  "function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) returns (uint256 amountA, uint256 amountB, uint256 liquidity)",
];

describe("Bootstrapper addLiquidity flow", function () {
  it("pulls tokens, pays skim, and calls router", async function () {
    const [deployer, creator, user, recipient] = await ethers.getSigners();

    // Deploy MockRouter
    const Router = await ethers.getContractFactory("MockRouter");
    const router = await Router.deploy();
    await router.waitForDeployment();

    // Deploy two EUSD tokens with no initial fee (0 initialFeeBps) so all tokens go to deployer
    // Then transfer to user for testing
    const EUSD = await ethers.getContractFactory("EUSD");
    const tokenA = await EUSD.deploy("TokenA", "TKA", creator.address, 1000000, 0, 0);
    await tokenA.waitForDeployment();
    const tokenB = await EUSD.deploy("TokenB", "TKB", creator.address, 1000000, 0, 0);
    await tokenB.waitForDeployment();

    // Transfer tokens from deployer to user (since they were minted to deployer as msg.sender)
    await tokenA.transfer(user.address, 1000000n);
    await tokenB.transfer(user.address, 1000000n);

    // Deploy Bootstrapper with skimFeeBps = 50 (0.5%)
    const Bootstrapper = await ethers.getContractFactory("Bootstrapper");
    const b = await Bootstrapper.deploy(router.getAddress(), creator.address, 50);
    await b.waitForDeployment();

    // User approves bootstrapper to pull desired amounts
    const amountA = 10000n;
    const amountB = 20000n;
    await (tokenA.connect(user) as any).approve(b.getAddress(), amountA);
    await (tokenB.connect(user) as any).approve(b.getAddress(), amountB);

    // Before balances
    const creatorBeforeA = await (tokenA as any).balanceOf(creator.address);
    const creatorBeforeB = await (tokenB as any).balanceOf(creator.address);

    // Call addLiquidity
    await (b.connect(user) as any).addLiquidity(
      await tokenA.getAddress(),
      await tokenB.getAddress(),
      false,
      amountA,
      amountB,
      1,
      1,
      recipient.address
    );

    // Check skim amounts were transferred to creator
    const skimA = (amountA * 50n) / 10000n;
    const skimB = (amountB * 50n) / 10000n;

    const creatorAfterA = await (tokenA as any).balanceOf(creator.address);
    const creatorAfterB = await (tokenB as any).balanceOf(creator.address);

    expect(creatorAfterA - creatorBeforeA).to.equal(skimA);
    expect(creatorAfterB - creatorBeforeB).to.equal(skimB);

    // Recipient should have received net amounts
    const recipientA = await (tokenA as any).balanceOf(recipient.address);
    const recipientB = await (tokenB as any).balanceOf(recipient.address);

    expect(recipientA).to.equal(amountA - skimA);
    expect(recipientB).to.equal(amountB - skimB);
  });
});
