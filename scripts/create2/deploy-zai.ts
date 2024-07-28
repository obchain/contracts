import hre, { ethers } from "hardhat";
import { buildBytecode } from "./create2";
import { waitForTx } from "../utils";

async function main() {
  const constructorArgs: any[] = ["0xe5159e75ba5f1C9E386A3ad2FC7eA75c14629572"];

  const [wallet] = await hre.ethers.getSigners();

  const deployer = await hre.ethers.getContractAt(
    "Deployer",
    "0xc07c1980C87bfD5de0DC77f90Ce6508c1C0795C3"
  );

  const factory = await hre.ethers.getContractFactory("ZaiStablecoin");

  const salt =
    "0xa518fb0108ec6d1659ec04d98aac4d5c06a0cebfe1e4ef55247ca5e262d5f50f";

  const bytecode = buildBytecode(
    ["address"],
    constructorArgs,
    factory.bytecode
  );

  const txPopulated = await deployer.deploy.populateTransaction(
    bytecode,
    ethers.id(salt)
  );

  const txR = await waitForTx(await wallet.sendTransaction(txPopulated));
  console.log(txR?.logs);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
