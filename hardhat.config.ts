import * as dotenv from "dotenv";

import "@nomicfoundation/hardhat-toolbox";
import { HardhatUserConfig } from "hardhat/config";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.21",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    Local: {
      url: "http://127.0.0.1:8545/",
      accounts: [
        "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
      ],
      // gas: 30000000,
      // gasPrice: 50000000,
    },
    MerlinTestnet: {
      url: "https://testnet-rpc.merlinchain.io",
      accounts: [
        process.env.TEST_SECRET_KEY ||
          "a58aadef3c5321f9601f2aa3c7e8cfc451fe09ca635c913d21b829f6614585f2",
      ],
      // gas: 30000000,
      // gasPrice: 50000000,
    },
    MerlinMainnet: {
      url: "https://rpc.merlinchain.io",
      accounts: [
        process.env.SECRET_KEY ||
          "a58aadef3c5321f9601f2aa3c7e8cfc451fe09ca635c913d21b829f6614585f2",
      ],
      // gas: 30000000,
      gasPrice: 50000000,
    },
    BitlayerTestnet: {
      url: "https://testnet-rpc.bitlayer.org",
      accounts: [
        process.env.TEST_SECRET_KEY ||
          "a58aadef3c5321f9601f2aa3c7e8cfc451fe09ca635c913d21b829f6614585f2",
      ],
      // gas: 30000000,
      // gasPrice: 50000000,
    },
    MantleSepolia: {
      url: "https://rpc.sepolia.mantle.xyz",
      accounts: [
        process.env.TEST_SECRET_KEY ||
          "a58aadef3c5321f9601f2aa3c7e8cfc451fe09ca635c913d21b829f6614585f2",
      ],
      // gas: 30000000,
      // gasPrice: 50000000,
    },
  },
  sourcify: {
    enabled: false,
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  mocha: {
    timeout: 40000,
  },
  // npx hardhat verify --network scrollTestnet 0x95ad51f4406bf2AF31e3A2e2d75262EE19432261 123
  etherscan: {
    apiKey: {
      MerlinTestnet: "abc",
      MerlinMainnet: "abc",
      BitlayerTestnet: "abc",
      BitlayerMainnet: "abc",
      MantleSepolia: "NM3TIFEK4CNK6B2F26SJEK8PYTIDHQ5VXF",
    },
    customChains: [
      {
        network: "MantleSepolia",
        chainId: 5003,
        urls: {
          // apiURL: "https://explorer.sepolia.mantle.xyz/api",
          // browserURL: "https://explorer.sepolia.mantle.xyz/",
          apiURL: "https://api-sepolia.mantlescan.xyz/api",
          browserURL: "https://sepolia.mantlescan.xyz/",
        },
      },
      {
        network: "MerlinTestnet",
        chainId: 686868,
        urls: {
          apiURL: "https://testnet-scan.merlinchain.io/api",
          browserURL: "https://testnet-scan.merlinchain.io",
        },
      },
      {
        network: "MerlinMainnet",
        chainId: 4200,
        urls: {
          apiURL: "https://scan.merlinchain.io/api",
          browserURL: "https://scan.merlinchain.io",
        },
      },
      {
        network: "BitlayerTestnet",
        chainId: 200810,
        urls: {
          apiURL: "https://api-testnet.btrscan.com/scan/api",
          browserURL: "https://testnet.btrscan.com",
        },
      },
    ],
  },
};

export default config;
