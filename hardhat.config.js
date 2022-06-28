/**
 * @type import('hardhat/config').HardhatUserConfig
 */
require("@nomiclabs/hardhat-waffle");
require('@nomiclabs/hardhat-ethers');
require("@nomiclabs/hardhat-etherscan");
require('@openzeppelin/hardhat-upgrades');

const { mnemonic, privateKey } = require('./secrets.json');

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545"
    },
    hardhat: {
    },
    testnet: {
      url: "https://http-testnet.hecochain.com",
      chainId: 256,
      gas: 3000000,
      gasPrice: 20000000000,
      // accounts: {mnemonic: mnemonic}
      accounts: [privateKey]
    },
    mainnet: {
      url: "https://http-mainnet.hecochain.com",
      chainId: 128,
      gas: 3000000,
      gasPrice: 20000000000,
      accounts: {mnemonic: mnemonic}
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.7.5",
        settings: {
          optimizer: {
            enabled: false
          }
        }
      },
      {
        version: "0.8.9",
        settings: {
          optimizer: {
            enabled: false
          }
        }
      }
    ],
    overrides: {
      "contracts/NFTBox.sol": {
        version: "0.5.8",
        settings: {
          optimizer: {
            enabled: false,
            // runs: 200
          }
        }
      }
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  mocha: {
    timeout: 2000000
  }
};


/*
Using MetaMask to send 0.5 HT to 0x164Bb112B4b7500C08D7C78B2e1eFf70b1361Ed4
https://testnet.hecoinfo.com/tx/0x56740a29bdb69de51869ff438d5132e235d18862750ec1e30f03b5cfd40b9ab7
*/
