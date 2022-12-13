const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");
const metagAddress = process.env.METAG_ADDRESS;

describe("MetagStakepool contract", function () {
    async function deployTokenFixture() {
        const [owner, addr1, addr2] = await ethers.getSigners();
        const MetagStakepool = await ethers.getContractFactory("MetagStakepool");
        const contract = await MetagStakepool.deploy(metagAddress, metagAddress);

        await contract.deployed();
        return { MetagStakepool, contract, owner, addr1, addr2 };
    }
    it("has an owner", async function () {
        const { contract, owner } = await loadFixture(deployTokenFixture);
        // const ownerBalance = await contract.balanceOf(owner.address);
        expect(await contract.owner()).to.equal(owner.address);
    });

    it("only Valid Amount", async function () {
        const { contract, owner } = await loadFixture(deployTokenFixture);
        const amount = ethers.utils.parseEther("3")
        await contract.depositTokens(amount);
    });
});