require("dotenv").config();
const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const metagAddress = process.env.TMETAG_ADDRESS
  const MetagStakepool = await ethers.getContractFactory("MetagStakepool");
  const contract = await MetagStakepool.deploy(metagAddress, metagAddress);

  await contract.deployed()

  console.log("MetagStakepool address:", contract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
      console.error(error);
      process.exit(1);
  });
