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
    heco_test: {
      url: "https://http-testnet.hecochain.com",
      chainId: 256,
      gas: 3000000,
      gasPrice: 20000000000,
      // accounts: {mnemonic: mnemonic}
      accounts: [privateKey]
    },
    heco_main: {
      url: "https://http-mainnet.hecochain.com",
      chainId: 128,
      gas: 3000000,
      gasPrice: 20000000000,
      accounts: {mnemonic: mnemonic}
    },
    cube_test: {
      url: "https://http-testnet.cube.network",
      // url: "https://http-testnet-archive.cube.network",
      // url: "https://http-testnet-sg.cube.network",
      // url: "https://http-testnet-jp.cube.network",
      // url: "https://http-testnet-us.cube.network",
      // url: "http://defi-node.huobiapps.com/cube_intertx_rpc",
      chainId: 1819,
      gas: 3000000,
      // gasPrice: "auto",
      gasPrice: 5000_000_000, // 5 gwei,
      // accounts: {mnemonic: mnemonic},
      accounts: [privateKey],
      timeout: 20000000
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


