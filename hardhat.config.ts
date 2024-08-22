import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-ethers";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-dependency-compiler";
import "hardhat-abi-exporter";
import "@openzeppelin/hardhat-upgrades";
import "hardhat-deploy";
import "solidity-coverage";
import "solidity-docgen";
import "hardhat-tracer";

import "@typechain/hardhat";
import "@nomicfoundation/hardhat-chai-matchers";

import dotenv from "dotenv";
import { loadTasks } from "./scripts/utils";
dotenv.config();

const defaultAccount = {
  mnemonic:
    process.env.SEED_PHRASE ||
    "test test test test test test test test test test test junk",
  path: "m/44'/60'/0'/0",
  initialIndex: 0,
  count: 20,
  passphrase: "",
};

const SKIP_LOAD = process.env.SKIP_LOAD === "true";
const TASK_FOLDERS = ["connext", "misc", "layerzero"];

// Prevent to load tasks before compilation and typechain
if (!SKIP_LOAD) {
  loadTasks(TASK_FOLDERS);
}

const _network = (url: string) => ({
  url,
  accounts: defaultAccount,
  saveDeployments: true,
});

const config: HardhatUserConfig = {
  abiExporter: {
    path: "./abi",
    runOnCompile: true,
    clear: true,
    spacing: 2,
    format: "minimal",
  },
  docgen: {
    pages: "files",
    exclude: ["interfaces", "tests"],
  },
  gasReporter: {
    // @ts-ignore
    reportFormat: "terminal",
    outputFile: "coverage/gasReport.txt",
    noColors: true,
    forceTerminalOutput: true,
    forceTerminalOutputFormat: "terminal",
  },
  dependencyCompiler: {
    paths: [
      "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol",
    ],
  },
  typechain: {
    outDir: "types",
    target: "ethers-v6",
  },
  solidity: {
    version: "0.8.21",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },
  networks: {
    hardhat: {
      // forking: {
      //   url: `https://rpc.ankr.com/eth`,
      // },
      accounts: defaultAccount,
    },
    arbitrum: _network("https://arb1.arbitrum.io/rpc"),
    base: _network("https://mainnet.base.org"),
    bsc: _network("https://rpc.ankr.com/bsc"),
    linea: _network("https://rpc.linea.build"),
    mainnet: _network("https://rpc.ankr.com/eth"),
    optimism: _network("https://mainnet.optimism.io"),
    sepolia: _network("https://rpc2.sepolia.org"),
    xlayer: _network("https://xlayerrpc.okx.com"),
  },
  namedAccounts: {
    deployer: 0,
    proxyAdmin: 1,
  },
  etherscan: {
    apiKey: {
      mainnet: process.env.ETHERSCAN_KEY || "",
      sepolia: process.env.ETHERSCAN_KEY || "",
      base: process.env.BASESCAN_KEY || "",
      arbitrumOne: process.env.ARBISCAN_KEY || "",
      xlayer: "test",
    },
    customChains: [
      {
        network: "xlayer",
        chainId: 196,
        urls: {
          apiURL:
            "https://www.oklink.com/api/v5/explorer/contract/verify-source-code-plugin/XLAYER",
          browserURL: "https://www.oklink.com/xlayer", //or https://www.oklink.com/xlayer for mainnet
        },
      },
    ],
  },
};

export default config;
