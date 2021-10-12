require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("@openzeppelin/hardhat-upgrades");

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.3",
  networks:{
    hardhat:{
      chainId: 1337
    }
    // rinkeby: {
		// 	url: "https://rinkeby.infura.io/v3/8669d625ab2d446c9d2600f2af74ae81", 
		// 	accounts: {
		// 		mnemonic: mnemonic(),
		// 	},
		// },
  }
};
