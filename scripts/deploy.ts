import { ethers } from "hardhat";
import * as fs from "fs";
import * as path from "path";
import "dotenv/config";

async function main() {
  // Canonical Base addresses (update AAVE_POOL to actual Base V3 Pool address!)
  const AAVE_POOL = process.env.AAVE_POOL || "0x4e033b8c5d5e...";
  const AERODROME_ROUTER = process.env.AERODROME_ROUTER || "0x6cb442acf35158d5eda88fe602221b67b400be3e";
  const AERODROME_FACTORY = process.env.AERODROME_FACTORY || "0x4200000000000000000000000000000000000006";
  const USDC = process.env.USDC || "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913";
  const CREATOR = process.env.CREATOR || "0xfbdb59298ea0b9d867897cceddb0de1e2b03909c";

  // Deploy StableForgeFactory
  const StableForgeFactory = await ethers.getContractFactory("StableForgeFactory");
  const factory = await StableForgeFactory.deploy(
    AAVE_POOL,
    AERODROME_ROUTER,
    AERODROME_FACTORY,
    USDC,
    CREATOR
  );
  await factory.waitForDeployment();

  const addr = await factory.getAddress();
  console.log(`StableForgeFactory deployed at: ${addr}`);

  // Save to deploy.out for CI/CD injection
  const outPath = path.join(__dirname, "..", "deploy.out");
  fs.writeFileSync(outPath, `StableForgeFactory: ${addr}\n`);
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});


