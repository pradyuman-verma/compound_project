const hre = require("hardhat");

async function main() {
  const myCompound = await hre.ethers.getContractFactory("Compound_sample");
  const compound = await myCompound.deploy();

  await compound.deployed();

  console.log("compound_sample deployed to:", compound.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
