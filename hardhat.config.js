require("dotenv").config();

require('@openzeppelin/hardhat-upgrades');
require('@nomiclabs/hardhat-waffle');
require("hardhat-gas-reporter");
require("hardhat-contract-sizer");

module.exports = {
  solidity: "0.8.9",
  networks: {
    mainnet: {
      url: process.env.AVALANCHE_URL || "",
      gas: 2100000,
      gasPrice: 225000000000,
      chainId: 43114,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    // artifacts: "./frontend/src/artifacts"
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  settings: {
    optimizer: {
      enabled: true,
      runs: 1,
    }
  },
};
