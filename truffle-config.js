require('dotenv').config();
require('babel-register');
require('babel-polyfill');

const Web3 = require('web3');
const HDWalletProvider = require("@truffle/hdwallet-provider");

const { env } = process;

const getWalletProvider = networkName => {
  const endpoint = `wss://${networkName}.infura.io/ws/v3/${env.INFURA_API_KEY}`;
  return new HDWalletProvider(env.MNEMONIC, endpoint, env.MINTER_GANACHE_INDEX);
};

const chainIds = {
  ganache: 1337,
  goerli: 5,
  hardhat: 31337,
  kovan: 42,
  mainnet: 1,
  rinkeby: 4,
  ropsten: 3,
};

module.exports = {
  api_keys: {
    etherscan: env.ETHERSCAN_API_KEY,
  },
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*",
      from: `${ env.MINTER_ADDRESS_LOCALHOST }`,
      gasPrice: '0x64',
    },
    mainnet: {
      provider: () => getWalletProvider('mainnet'),
      network_id: chainIds.mainnet,
      from: `${ env.MINTER_ADDRESS }`,
      gasPrice: Web3.utils.toWei('115', 'gwei'),
      gas: 5750000,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: false,
      networkCheckTimeout: 1000000,
    },
    kovan: {
      provider: () => getWalletProvider('kovan'),
      network_id: chainIds.kovan,
      from: `${ env.MINTER_ADDRESS }`,
      gas: 5500000,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true,
    },
    ropsten: {
      provider: () => getWalletProvider('ropsten'),
      gas: 8000000,
      gasPrice: Web3.utils.toWei("50", "gwei"),
      network_id: chainIds.ropsten,
      from: `${ env.MINTER_ADDRESS }`,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true,
    },
    rinkeby: {
      provider: () => getWalletProvider('rinkeby'),
      gas: 10000000,
      gasPrice: 25000000000,
      network_id: chainIds.rinkeby,
      from: `${ env.MINTER_ADDRESS }`,
      confirmations: 2,
      timeoutBlocks: 200,
      networkCheckTimeout: 1000000,
      skipDryRun: true,
    },
    goerli: {
      provider: () => getWalletProvider('goerli'),
      network_id: chainIds.goerli,
      gas: 8500000,
      gasPrice: Web3.utils.toWei("50", "gwei"),
      from: `${ env.MINTER_ADDRESS }`,
      confirmations: 2,
      timeoutBlocks: 200,
      networkCheckTimeout: 1000000,
      skipDryRun: true,
    },
  },
  contracts_directory: 'contracts',
  contracts_build_directory: 'abis',
  compilers: {
    solc: {
      optimizer: {
        enabled: true,
        runs: 200
      },
      version: "^0.8.0"
    },
  },
  plugins: [
    "truffle-contract-size",
    "truffle-plugin-verify",
  ]
};
