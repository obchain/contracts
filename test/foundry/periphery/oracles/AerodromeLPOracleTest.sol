// SPDX-License-Identifier: GPL-3.0

// ███╗   ███╗ █████╗ ██╗  ██╗ █████╗
// ████╗ ████║██╔══██╗██║  ██║██╔══██╗
// ██╔████╔██║███████║███████║███████║
// ██║╚██╔╝██║██╔══██║██╔══██║██╔══██║
// ██║ ╚═╝ ██║██║  ██║██║  ██║██║  ██║
// ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝

// Website: https://maha.xyz
// Discord: https://discord.gg/mahadao
// Twitter: https://twitter.com/mahaxyz_

pragma solidity 0.8.21;

import {AerodromeLPOracle, IAerodromePool} from "../../../../contracts/periphery/oracles/AerodromeLPOracle.sol";
import {FixedPriceOracle} from "../../../../contracts/periphery/oracles/FixedPriceOracle.sol";

import {
  AggregatorV3Interface,
  IERC4626,
  MorphoChainlinkOracleV2
} from "../../../../lib/morpho-blue-oracles/src/morpho-chainlink/MorphoChainlinkOracleV2.sol";
import {BaseZaiTest, IERC20, console} from "../../base/BaseZaiTest.sol";

contract AerodromeLPOracleTest is BaseZaiTest {
  IAerodromePool public pool;

  string BASE_RPC_URL = vm.envString("BASE_RPC_URL");

  function setUp() public {
    uint256 baseFork = vm.createFork(BASE_RPC_URL);
    vm.selectFork(baseFork);
    vm.rollFork(19_141_574);

    pool = IAerodromePool(0x72d509aFF75753aAaD6A10d3EB98f2DBC58C480D);
  }

  // function test_oracle_lp() public {
  //   FixedPriceOracle fixedOracle = new FixedPriceOracle(1e8, 8);
  //   AerodromeLPOracle oracle = new AerodromeLPOracle(address(fixedOracle), address(fixedOracle), address(pool));

  //   uint256 r0 = pool.reserve0();
  //   uint256 r1 = pool.reserve1();
  //   uint256 xyK = r0 * r1;

  //   // 0.029999999999998 ETH = 60,000$ of LP at this block
  //   // assertEq(oracle.getK(), pool.getK(), "!oracle.getK");

  //   uint256 k = oracle.getK();

  //   console.log("r0", r0);
  //   console.log("r1", r1);
  //   console.log("oracle.getK();", k);
  //   console.log("oracle._k();", oracle._k(30_000e18, 30_000e6));
  //   console.log("oracle._f();", oracle._f(30_000e6, 30_000e18));
  //   console.log("pool.getK();", pool.getK());
  //   console.log("oracle.solution(x, k);", oracle.solution(30_000e18, k));
  //   assertEq(oracle.sqrt(1e8), 1e4, "!oracle.sqrt");

  //   // console.log("oracle.getK", oracle.getK());
  //   // console.log("xy = k", xyK);

  //   // console.log("_f", oracle._f(r0, r1));
  //   // console.log("getY r0", oracle.getY(r0, oracle._k(r0, r1), r1));
  //   // console.log("getY r1", oracle.getY(r1, oracle._k(r0, r1), r0));

  //   // console.log("oracle.decimals0", oracle.decimals0());
  //   // console.log("oracle.decimals1", oracle.decimals1());
  //   // console.log("oracle.getPriceFor():", oracle.getPriceFor(29_999_999_999_998_000));

  //   assertEq(oracle.getPriceFor(29_999_999_999_998_000), 60_000, "!oracle.getPriceFor");

  //   MorphoChainlinkOracleV2 morphoOracle = new MorphoChainlinkOracleV2(
  //     IERC4626(address(0)), // IERC4626 baseVault,
  //     1, // uint256 baseVaultConversionSample,
  //     AggregatorV3Interface(address(oracle)), // AggregatorV3Interface baseFeed1,
  //     AggregatorV3Interface(address(0)), // AggregatorV3Interface baseFeed2,
  //     1, // uint256 baseTokenDecimals,
  //     IERC4626(address(0)), // IERC4626 quoteVault,
  //     1, // uint256 quoteVaultConversionSample,
  //     AggregatorV3Interface(address(0)), // AggregatorV3Interface quoteFeed1,
  //     AggregatorV3Interface(address(0)), // AggregatorV3Interface quoteFeed2,
  //     1 // uint256 quoteTokenDecimals
  //   );

  //   assertEq(morphoOracle.price() / 1e36, 50_000, "!morphoOracle.price");
  // }
}
