/**
 * @type import('hardhat/config').HardhatUserConfig
 */
 require("@nomiclabs/hardhat-waffle")
 require("hardhat-gas-reporter")
 require("@nomiclabs/hardhat-etherscan")
 require("dotenv").config()
 require("solidity-coverage")
 require("hardhat-deploy")
 require("hardhat-contract-sizer")


const RINKEBY_RPC_URL = process.env.RINKEBY_RPC_URL
const PRIVATE_KEY = process.env.PRIVATE_KEY
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || "F3J28Z81P2VIF3AJDRN43ADQBTU3XBTYB7"
const REPORT_GAS = process.env.REPORT_GAS
const COINMARKETCAP_API_KEY = process.env.COINMARKETCAP_API_KEY

const KOVAN_RPC_URL = process.env.KOVAN_RPC_URL
const MAINNET_RPC_URL = process.env.MAINNET_RPC_URL

module.exports = {
  // solidity: "0.8.8",
  solidity: {
      compilers: [{version: "0.8.8"}, {version: "0.6.6"}, {version: "0.4.19"}, {version: "0.6.12"}],
  },
  defaultNetwork: "hardhat",
  networks: {
      rinkeby: {
          url: RINKEBY_RPC_URL,
          accounts: [PRIVATE_KEY],
          chainId: 4,
          blockConfirmations: 6,
          // gas: 2100000,
          // gasPrice: 130000000000
      },
      hardhat: {
        chainId: 31337,
        forking: {
            url: MAINNET_RPC_URL,
        },
    },
      kovan: {
        url: KOVAN_RPC_URL,
        accounts: [PRIVATE_KEY],
        chainId: 42,
        blockConfirmations: 6,
      },
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
    second: {
      default: 1,
    },
    third: {
      default: 2,
    },
    forth: {
      default: 3,
    },
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },
  gasReporter: {
    enabled: REPORT_GAS,
    currency: "USD",
    outputFile: "gas-report.txt",
    noColors: true,
    coinmarketcap: COINMARKETCAP_API_KEY,
    token: "AVAX"
  },
}
