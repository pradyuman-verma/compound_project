require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("@openzeppelin/hardhat-upgrades");
require('dotenv').config()

/**
 * @type import('hardhat/config').HardhatUserConfig
 */

module.exports = {
  solidity: "0.8.3",
  defaultNetwork: "hardhat",
  networks:{
    hardhat:{
      forking:{
        url: `https://eth-mainnet.alchemyapi.io/v2/${process.env.ALCHEMY_ENDPOINT}`,
        blockNumber: 13405033
      }
    }
  }
};
