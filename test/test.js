require('dotenv').config()
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Compound-testing", function () {
  let myCompound, compound, owner;

  const DAI = process.env.DAI;
  const CDAI = process.env.CDAI;
  const CETH = process.env.CETH;
  const ACC = process.env.USER;

  //describe("ETH-TESTING", function () {
    beforeEach(async () => {
    console.log("1")
      myCompound = await ethers.getContractFactory("CompoundSample");
    console.log("2")

      compound = await myCompound.deploy();
    console.log("3")

     // [owner, _] = await ethers.getSigners();   
    console.log("4")

      await compound.deployed();
      //myCompound.connect(owner);
      console.log("Deployed Successfully");
    });

    let cTokenAmount = 3000;

    it('blah blah blah', () => {
      console.log(5)
      await artifacts.readArtifact("CEth")
      .then((x) => {
        console.log(x);
      })
      // .then(() => {
      //   console.log(5.5)
      //   console.log(cEthArtifact.abi);
      // });
      //console.log(cEthArtifact);
      console.log(6)
    });

    // const cEth = new ethers.Contract(CETH, cEthArtifact.abi, ethers.provider);
    // const cEthWithSigner = cEth.connect(owner);

    // network.provider.send("hardhat_setBalance", [
    //     user.address,
    //     ethers.utils.parseEther('10.0').toHexString(),
    // ]);

    // it('Should supply Eth to compound', async () => {
    //   await myCompound.supplyEthToCompound(CETH, {value: ethers.utils.parseEther('1.0').toHexString()});
    // }).timeout(100000);

    // it('Should Withdraw Eth from compound', async () => {
    //   await myCompound.withdrawEth(cTokenAmount, CETH);
    // }).timeout(100000);
  //});
});
