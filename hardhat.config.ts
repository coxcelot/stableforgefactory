import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "dotenv/config";

const accounts: string[] =
  process.env.PK
    ? [process.env.PK]
    : process.env.MNEMONIC
    ? { mnemonic: process.env.MNEMONIC } as any
    : [];

// Hardcoded creator address
export const CREATOR = "0xfbdb59298ea0b9d867897cceddb0de1e2b03909c";

const config: HardhatUserConfig = {
  solidity: "0.8.20",
  networks: {
    base: {
      url: process.env.BASE_RPC || "",
      accounts,
    },
    sepolia: {
      url: process.env.SEPOLIA_RPC || "",
      accounts,
    },
  },
};

export default config;


