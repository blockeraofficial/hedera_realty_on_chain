require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-chai-matchers");
require("@nomiclabs/hardhat-ethers");
// Import dotenv module to access variables stored in the .env file
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  mocha: {
    timeout: 3600000,
  },
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 500,
      },
    },
  },
  // This specifies network configurations used when running Hardhat tasks
  defaultNetwork: "local",
  networks: {
    local: {
      // Your Hedera Local Node address pulled from the .env file
      url: process.env.LOCAL_NODE_ENDPOINT,
      // Your local node operator private key pulled from the .env file
      accounts: [process.env.LOCAL_NODE_OPERATOR_PRIVATE_KEY],
    },
    testnet: {
      // HashIO testnet endpoint from the TESTNET_ENDPOINT variable in the .env file
      url: process.env.TESTNET_ENDPOINT,
      // Your ECDSA account private key pulled from the .env file
      accounts: [process.env.TESTNET_OPERATOR_PRIVATE_KEY],
    },

    /**
     * Uncomment the following to add a mainnet network configuration
     */
    //   mainnet: {
    //     // HashIO mainnet endpoint from the MAINNET_ENDPOINT variable in the .env file
    //     url: process.env.MAINNET_ENDPOINT,
    //     // Your ECDSA account private key pulled from the .env file
    //     accounts: [process.env.MAINNET_OPERATOR_PRIVATE_KEY],
    // },

    /**
     * Uncomment the following to add a previewnet network configuration
     */
    //   previewnet: {
    //     // HashIO previewnet endpoint from the PREVIEWNET_ENDPOINT variable in the .env file
    //     url: process.env.PREVIEWNET_ENDPOINT,
    //     // Your ECDSA account private key pulled from the .env file
    //     accounts: [process.env.PREVIEWNET_OPERATOR_PRIVATE_KEY],
    // },
  },
};
