import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "dotenv/config";

const config: HardhatUserConfig = {
  solidity: "0.8.20",
  networks: {
    base: {
      url: process.env.BASE_RPC || "",
      accounts: process.env.PK
        ? [process.env.PK] // use raw private key
        : process.env.MNEMONIC
        ? { mnemonic: process.env.MNEMONIC } as any // use seed phrase
        : [],
    },
    sepolia: {
      url: process.env.SEPOLIA_RPC || "",
      accounts: process.env.PK
        ? [process.env.PK]
        : process.env.MNEMONIC
        ? { mnemonic: process.env.MNEMONIC } as any
        : [],
    },
  },
};

export default config;


