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

import {PegStabilityModule} from "../../../../contracts/core/psm/PegStabilityModule.sol";
import {StakingLPRewards} from "../../../../contracts/periphery/staking/StakingLPRewards.sol";

import {IERC20, MockCurvePool} from "../../../../contracts/mocks/MockCurvePool.sol";
import {ZapAerodromePoolUSDC} from "../../../../contracts/periphery/zaps/implementations/base/ZapAerodromePoolUSDC.sol";
import {BaseZaiTest, console} from "../../base/BaseZaiTest.sol";

contract ZapAerodromePoolUSDCTest is BaseZaiTest {
  StakingLPRewards internal staking;
  ZapAerodromePoolUSDC internal zap;
  PegStabilityModule internal psmUSDC;
  MockCurvePool internal pool;

  string BASE_RPC_URL = vm.envString("BASE_RPC_URL");

  function test_zap_fork() public {
    uint256 mainnetFork = vm.createFork(BASE_RPC_URL);
    vm.selectFork(mainnetFork);
    vm.rollFork(19_141_574);

    address user = 0x1F09Ec21d7fd0A21879b919bf0f9C46e6b85CA8b;
    IERC20 _usdc = IERC20(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913);
    IERC20 _zai = IERC20(0x0A27E060C0406f8Ab7B64e3BEE036a37e5a62853);
    IERC20 _pool = IERC20(0x72d509aFF75753aAaD6A10d3EB98f2DBC58C480D);
    IERC20 _staking = IERC20(0x1097dFe9539350cb466dF9CA89A5e61195A520B0);
    address _restaking = 0xA07cf1c081F46524A133c1B6E8eE0B5f96A51255;
    address _router = 0xcF77a3Ba9A5CA399B7c97c74d54e5b1Beb874E43;
    address odos = 0x19cEeAd7105607Cd444F5ad10dd51356436095a1;

    ZapAerodromePoolUSDC _zap = new ZapAerodromePoolUSDC(
      address(_staking), // lp staking pool
      _restaking, // bridge
      _router,
      odos
    );

    vm.startPrank(user);
    _usdc.approve(address(_zap), type(uint256).max);
    _zap.zapIntoLP(100e6, 0);

    vm.stopPrank();

    assertGe(_pool.balanceOf(address(_staking)), 0, "!pool.balanceOf(staking)");
    assertEq(_usdc.balanceOf(_restaking), 50_100_000, "!usdc.balanceOf(psmUSDC)");

    assertEq(_zai.balanceOf(address(_zap)), 0, "!zai.balanceOf(zap)");
    assertEq(_usdc.balanceOf(address(_zap)), 0, "!usdc.balanceOf(zap)");

    assertApproxEqAbs(_staking.balanceOf(user), 50 * 1e12, 1e12, "!staking.balanceOf(user)");
  }

  function test_zap_fork_depegged() public {
    uint256 mainnetFork = vm.createFork(BASE_RPC_URL);
    vm.selectFork(mainnetFork);
    vm.rollFork(20_727_180);

    address user = 0x1F09Ec21d7fd0A21879b919bf0f9C46e6b85CA8b;
    IERC20 _usdc = IERC20(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913);
    IERC20 _zai = IERC20(0x0A27E060C0406f8Ab7B64e3BEE036a37e5a62853);
    IERC20 _pool = IERC20(0x72d509aFF75753aAaD6A10d3EB98f2DBC58C480D);
    IERC20 _staking = IERC20(0x1097dFe9539350cb466dF9CA89A5e61195A520B0);
    address _restaking = 0xA07cf1c081F46524A133c1B6E8eE0B5f96A51255;
    address _router = 0xcF77a3Ba9A5CA399B7c97c74d54e5b1Beb874E43;
    address odos = 0x19cEeAd7105607Cd444F5ad10dd51356436095a1;

    ZapAerodromePoolUSDC _zap = new ZapAerodromePoolUSDC(
      address(_staking), // lp staking pool
      _restaking, // bridge
      _router,
      odos
    );

    vm.startPrank(user);
    _usdc.approve(address(_zap), type(uint256).max);
    _zap.zapIntoLP(100e6, 0);

    vm.stopPrank();

    assertGe(_pool.balanceOf(address(_staking)), 0, "!pool.balanceOf(staking)");
    assertEq(_usdc.balanceOf(_restaking), 15_273_433_195, "!usdc.balanceOf(psmUSDC)");

    assertEq(_zai.balanceOf(address(_zap)), 0, "!zai.balanceOf(zap)");
    assertEq(_usdc.balanceOf(address(_zap)), 0, "!usdc.balanceOf(zap)");

    assertApproxEqAbs(_staking.balanceOf(user), 50 * 1e12, 1e12, "!staking.balanceOf(user)");
  }
}
