require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("@openzeppelin/hardhat-upgrades");

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
      },
      chainId: 1337
    },
    rinkeby: {
			url: "https://rinkeby.infura.io/v3/8669d625ab2d446c9d2600f2af74ae81", 
			accounts: ['0xfc8c9d67f559b7d0ef3a3282e98d234798a0f346b9fc8068508e6b29c5e2575b']
		},
  }
};
