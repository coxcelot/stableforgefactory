import { ethers } from "hardhat";
import { expect } from "chai";

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

describe("StableForgeFactory / EUSD deployment", function () {
  it("deploys token and transfers initial fee to creator", async function () {
    const [deployer, creator] = await ethers.getSigners();

    const Factory = await ethers.getContractFactory("StableForgeFactory");
    // Ensure creator address is in checksum format
    const creatorAddr = ethers.getAddress(creator.address);
    
    const factory = await Factory.deploy(
      ethers.ZeroAddress, // AAVE_POOL placeholder
      ethers.getAddress("0x6cb442acf35158d5eda88fe602221b67b400be3e"), // AERODROME_ROUTER
      ethers.getAddress("0x4200000000000000000000000000000000000006"), // AERODROME_FACTORY
      ethers.getAddress("0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"), // USDC
      creatorAddr
    );
    await factory.waitForDeployment();

    const tx = await factory.deployToken("Extra Stable", "EUSD", 1000000000n);
    const receipt = await tx.wait();

    // Get the token address from transaction receipt
    if (!receipt || receipt.logs.length === 0) {
      throw new Error("No logs in receipt");
    }

    // Find the TokenDeployed event log
    const tokenDeployedTopic = factory.interface.getEvent("TokenDeployed")?.topicHash;
    const eventLog = receipt.logs.find((l) => l.topics[0] === tokenDeployedTopic);
    expect(eventLog).to.not.be.undefined;

    // Decode the event to extract token address
    const parsedLog = factory.interface.parseLog(eventLog!);
    const tokenAddr = parsedLog?.args?.[0];

    const Token = await ethers.getContractAt("EUSD", tokenAddr);
    const balance = await Token.balanceOf(creatorAddr);
    expect(balance).to.equal(20000000n); // 2% of 1,000,000,000
  });
});
