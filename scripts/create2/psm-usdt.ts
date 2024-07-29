import hre, { ethers, network } from "hardhat";
import { buildBytecode } from "./create2";
import { waitForTx } from "../utils";

async function main() {
  const factory = await hre.ethers.getContractFactory("MAHAProxy");
  const impl = await hre.ethers.getContractFactory("PegStabilityModule");

  const implArgs = [
    "0x69000405f9dce69bd4cbf4f2865b79144a69bfe0", // address _zai,
    "0xdac17f958d2ee523a2206206994597c13d831ec7", // address _collateral,
    "0x1F09Ec21d7fd0A21879b919bf0f9C46e6b85CA8b", // address _governance,
    1e6, // uint256 _newRate,
    100000000n * 10n ** 6n, // uint256 _supplyCap,
    100000000n * 10n ** 18n, // uint256 _debtCap,
    0, // uint256 _mintFeeBps,
    300, // uint256 _redeemFeeBps,
    "0x6357EDbfE5aDA570005ceB8FAd3139eF5A8863CC", // address _feeDestination
  ];

  const initData = impl.interface.encodeFunctionData("initialize", implArgs);

  const constructorArgs: any[] = [
    "0xC17596890598282dE86028B24C0C4885a9261874",
    "0x69000f2f879ee598ddf16c6c33cfc4f2d983b6bd",
    initData,
  ];
  const salt =
    "0x7e8fb0add4a06b3338408ee58cad371d97539af6e9ae9671213152017b6e43f4";
  const address = "0x690006c6bcd62d06b935050729b3004e962ba708";

  const [wallet] = await hre.ethers.getSigners();
  const deployer = await hre.ethers.getContractAt(
    "Deployer",
    "0x21F0F750E2d576AD5d01cFDDcF2095e8DA5b0fb0"
  );

  const bytecode = buildBytecode(
    ["address", "address", "bytes"],
    constructorArgs,
    factory.bytecode
  );

  const txPopulated = await deployer.deploy.populateTransaction(
    bytecode,
    ethers.id(salt)
  );

  const txR = await waitForTx(await wallet.sendTransaction(txPopulated));
  console.log(txR?.logs);

  if (network.name !== "hardhat") {
    await hre.deployments.save("PegStabilityModule-USDT", {
      address: address,
      args: implArgs,
      abi: impl.interface.format(true),
    });

    await hre.deployments.save("PegStabilityModule-USDT-Proxy", {
      address: address,
      args: constructorArgs,
      abi: factory.interface.format(true),
    });

    await hre.run("verify:verify", {
      address: address,
      constructorArguments: constructorArgs,
    });
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
