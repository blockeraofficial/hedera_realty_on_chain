const { ethers } = require("hardhat")

async function main() {

  const TESTNET_OPERATOR_PRIVATE_KEY = process.env.TESTNET_OPERATOR_PRIVATE_KEY;
  const TESTNET_ENDPOINT = process.env.TESTNET_ENDPOINT;

  const provider = new ethers.providers.JsonRpcProvider(TESTNET_ENDPOINT);
  const wallet = new ethers.Wallet(TESTNET_OPERATOR_PRIVATE_KEY, provider);

  const HederaAssetManagerContract = await ethers.getContractFactory("HederaAssetManagerContract", wallet);
  
  const contract = await HederaAssetManagerContract.deploy();

  const contractAddress = (await contract.deployTransaction.wait()).contractAddress;

  console.log(`HederaAssetManagerContract Contract Address: ${contractAddress}`);

  return contractAddress;

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })

// HederaAssetManagerContract Contract Address: 0x5D020b0a4560dDE404864268499bfF9bdDDdf6BB