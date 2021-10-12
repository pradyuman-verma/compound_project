const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Compound-testing", function () {
  let myCompound, compound;

  beforeEach(async () => {
    myCompound = await ethers.getContractFactory("CompoundSample");
    const [owner, addr1, ...addrs] = await ethers.getSigners();   
    compound = await myCompound.deploy(owner.getAddress());
    await compound.deployed();
  });

  it("supplyEthToCompound should return true", async function () {
    expect(await compound.supplyEthToCompound(0x4ddc2d193948926d02f9b1fe9e1daa0718270ed5, 2))
    .to
    .equal(true);
  });

  // it("withdrawEth should return true", async function () {
  //   expect(await compound.withdrawEth(10, 0xd6801a1dffcd0a410336ef88def4320d6df1883e))
  //   .to
  //   .equal(true);
  // });
});
