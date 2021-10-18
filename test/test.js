require('dotenv').config()
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Compound-testing", function () {
  let myCompound, compound, owner;

  const {DAI, CDAI, CETH, DUMMY_USER} = process.env;

  function set_balance(_address) {
    network.provider.send("hardhat_setBalance", [
      _address,
      ethers.utils.parseEther('10.0').toHexString()
    ]);
  }
  
  // function impersonate_account() {
  //   const tokenArtifact = await artifacts.readArtifact("IERC20");
  //   const token = new ethers.Contract(DAI, tokenArtifact.abi, ethers.provider);
  //   const signer = token.connect(owner);
  
  //   await hre.network.provider.request({
  //     method: "hardhat_impersonateAccount",
  //     params: [DUMMY_USER],
  //   });
  
  //   const signer = await ethers.getSigner(DUMMY_USER);
  
  //   await token.connect(signer).transfer(owner.address, ethers.utils.parseUnits("0.000001", 18));
  
  //   await hre.network.provider.request({
  //       method: "hardhat_stopImpersonatingAccount",
  //       params: [DUMMY_USER],
  //   });
  
  //   await signer.approve(compound.address, ethers.utils.parseUnits("0.000001", 18));
  // }

  describe("ETH-TESTING", function () {
    beforeEach(async () => {
      myCompound = await ethers.getContractFactory("CompoundSample");
      compound = await myCompound.deploy();
      [owner, add1, add2] = await ethers.getSigners();   
      await compound.deployed();
    });

    it('Should deploy successfully', async () => {
      console.log("Deployed Successfully");
    })

    it('Should supply and withdraw Eth to/from Compound', async () => {
      set_balance(owner.address);

      await compound.supplyEthToCompound(CETH, {value: ethers.utils.parseEther('1.0').toHexString()});
      console.log("Eth supplied successfully");

      await compound.withdrawEth(3000, CETH);
      console.log("Ether Withdrawn successfully");
    }).timeout(100000);

    it('Should borrow and repay Eth', async () => {  
      set_balance(DUMMY_USER);
      set_balance(owner.address);
      impersonate_account();

      await compound.supplyErc20ToCompound(DAI, CDAI, ethers.utils.parseUnits("0.000001", 18));
      console.log("Erc20 supplied successfully");

      await compound.borrowEth(CETH, CDAI, 100);
      console.log("Eth Borrowed");

      await compound.EthRepayBorrow(CETH, {value: 100});
      console.log("Eth repayed");
    }).timeout(100000);
  });

  // describe("Erc20-TESTING", function () {
  //   beforeEach(async () => {
  //     myCompound = await ethers.getContractFactory("CompoundSample");
  //     compound = await myCompound.deploy();
  //     [owner, add1, add2] = await ethers.getSigners();   
  //     await compound.deployed();
  //   });

  //  it('Should deploy successfully', async () => {
  //    console.log("Deployed Successfully");
  //  })
  //   it('Should supply, withdraw, borrow, repay Erc20 to/from Compound', async () => {    
  //     set_balance(DUMMY_USER);
  //     set_balance(owner.address);
  //     impersonate_account();

  //     await compound.supplyErc20(DAI, CDAI, ethers.utils.parseUnits("0.000001", 18));
  //     console.log("Erc20 supplied successfully!")

  //     await compound.borrowErc20(CDAI, DAI, 100000);
  //     console.log("Erc20 Borrowed successfully!")

  //     await compound.paybackErc20(DAI, CDAI, 100000); 
  //     console.log("Erc20 payback done!")

  //     await compound.withdrawErc20(3000, CDAI, DAI);
  //     console.log("Erc20 Withdrawn successfully!")
  //   }).timeout(100000);
  //});
});
