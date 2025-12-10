import { ethers } from "hardhat";
import "dotenv/config";
import * as fs from 'fs';
import * as path from 'path';
import { CREATOR } from "../hardhat.config";

async function main() {
  const pool = process.env.AAVE_POOL!;
  const router = process.env.AERODROME_ROUTER!;
  const factory = process.env.AERODROME_FACTORY!;
  const usdc = process.env.USDC!;

  console.log("Deploying StableForgeFactory to Base mainnet...");

  const StableForgeFactory = await ethers.getContractFactory("StableForgeFactory");
  const sf = await StableForgeFactory.deploy(pool, router, factory, usdc, CREATOR);
  await sf.waitForDeployment();

  const factoryAddress = await sf.getAddress();
  console.log(`StableForgeFactory deployed to: ${factoryAddress}`);

  // --- Step 1: Write Factory address to deploy.out ---
  const output = `StableForgeFactory Address: ${factoryAddress}\nBaseScan Link: https://basescan.org/address/${factoryAddress}`;
  fs.writeFileSync('deploy.out', output);
  console.log("Deployment output written to deploy.out");

  // --- Step 2: Inject Factory address into frontend/index.html ---
  const htmlPath = path.join(__dirname, '../frontend/index.html');
  let htmlContent = fs.readFileSync(htmlPath, 'utf8');

  const placeholder = 'FACTORY_ADDRESS_PLACEHOLDER';
  const newLink = `<a href="https://basescan.org/address/${factoryAddress}" target="_blank" class="text-blue-400 hover:text-blue-300 font-mono text-sm underline transition-colors">${factoryAddress}</a>`;
  
  // Replace all instances of the placeholder with the new link
  const updatedHtmlContent = htmlContent.replace(
      new RegExp(placeholder, 'g'), 
      newLink
  );

  fs.writeFileSync(htmlPath, updatedHtmlContent);
  console.log("frontend/index.html updated with factory address and BaseScan link.");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});


