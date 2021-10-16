require("dotenv").config();
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Compound-testing", function () {
  let myCompound, compoundProxy, owner;

  const { DAI, CDAI, CETH, ACC, COMPTROLLER, PRICEFEED } = process.env;

  function set_balance(_address) {
    network.provider.send("hardhat_setBalance", [
      _address,
      ethers.utils.parseEther("10.0").toHexString(),
    ]);
  }

  function impersonate_account() {
    const tokenArtifact = await artifacts.readArtifact("IERC20");
    const token = new ethers.Contract(DAI, tokenArtifact.abi, ethers.provider);
    const signer = token.connect(owner);

    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [ACC],
    });

    const signer = await ethers.getSigner(ACC);

    await token
      .connect(signer)
      .transfer(owner.address, ethers.utils.parseUnits("0.000001", 18));

    await hre.network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [ACC],
    });

    await signer.approve(
      compound.address,
      ethers.utils.parseUnits("0.000001", 18)
    );
  }

  describe("ETH-TESTING", function () {
    beforeEach(async () => {
      myCompound = await ethers.getContractFactory("CompoundSample");
      compoundProxy = await upgrades.deployProxy(
        myCompound,
        [COMPTROLLER, PRICEFEED, 0],
        { initializer: "set_init", unsafeAllow: ["delegatecall"] }
      );
      [owner, add1, add2] = await ethers.getSigners();
      await compoundProxy.deployed();
    });

    it("Should deploy proxy", async () => {
      console.log("Proxy Deployed Successfully");
    });

    it("Should supply and withdraw Eth to/from Compound", async () => {
      set_balance(owner.address);

      await compoundProxy.supplyEthToCompound(CETH, {
        value: ethers.utils.parseEther("1.0").toHexString(),
      });
      console.log("Eth supplied successfully");

      await compoundProxy.withdrawEth(3000, CETH);
      console.log("Ether Withdrawn successfully");
    }).timeout(100000);

    it("Should borrow and repay Eth", async () => {
      set_balance(ACC);
      set_balance(owner.address);
      impersonate_account();

      await compoundProxy.supplyErc20ToCompound(
        DAI,
        CDAI,
        ethers.utils.parseUnits("0.000001", 18)
      );
      console.log("Erc20 supplied successfully");

      await compoundProxy.borrowEth(CETH, CDAI, 1000);
      console.log("Eth Borrowed");

      await compoundProxy.EthRepayBorrow(CETH, { value: 1000 });
      console.log("Eth repayed");
    }).timeout(100000);
  });

  describe("Erc20-TESTING", function () {
    beforeEach(async () => {
      myCompound = await ethers.getContractFactory("CompoundSample");
      compoundProxy = await upgrades.deployProxy(
        myCompound,
        [COMPTROLLER, PRICEFEED, 0],
        { initializer: "set_init", unsafeAllow: ["delegatecall"] }
      );
      [owner, add1, add2] = await ethers.getSigners();
      await compoundProxy.deployed();
    });

    it("Should deploy proxy", async () => {
      console.log("Proxy Deployed Successfully");
    });

    it("Should supply, withdraw, borrow, repay Erc20 to/from Compound", async () => {
      set_balance(ACC);
      set_balance(owner.address);
      impersonate_account();

      await compoundProxy.supplyErc20(
        DAI,
        CDAI,
        ethers.utils.parseUnits("0.000001", 18)
      );
      console.log("Erc20 supplied successfully!");

      await compoundProxy.borrowErc20(CDAI, DAI, 10000);
      console.log("Erc20 Borrowed successfully!");

      await compoundProxy.paybackErc20(DAI, CDAI, 10000);
      console.log("Erc20 payback done!");

      await compoundProxy.withdrawErc20(3000, CDAI, DAI);
      console.log("Erc20 Withdrawn successfully!");
    }).timeout(100000);
  });
});
