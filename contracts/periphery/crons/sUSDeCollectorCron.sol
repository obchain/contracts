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

import {IOFT, MessagingFee, SendParam} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title sUSDeCollectorCron
 * @notice A contract that manages revenue distribution through USDC transfers, using Stargate for cross-chain messaging
 *         and optionally performing swaps via the ODOS router.
 * @dev The contract is upgradeable and inherits `Ownable2StepUpgradeable`. It supports setting an ODOS router,
 *      defining sZAI and USDC tokens, and has functions for swapping and cross-chain revenue distribution.
 */
contract sUSDeCollectorCron is AccessControlEnumerable {
  using SafeERC20 for IERC20;

  bytes32 public immutable EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
  address public immutable ODOS;
  IERC4626 public immutable SZAI;
  IERC20 public immutable ZAI;
  IERC20 public immutable SUSDE;
  IOFT public immutable OFT_ADAPTER;

  address public remoteDestination;
  uint32 public remoteEID;

  address public treasury;
  address public mahaBuyback;

  event RevenueDistributed(address indexed receiver, uint256 indexed amount);
  event RevenueCollected(uint256 indexed amount);
  event YieldDistributed(uint256 indexed amount, uint256 zaiSupply);

  constructor(address _odos, address _sZAI, address _sUSDe, address _zaiAdapter) {
    SZAI = IERC4626(_sZAI);
    SUSDE = IERC20(_sUSDe);
    ZAI = IERC20(SZAI.asset());
    ODOS = _odos;
    OFT_ADAPTER = IOFT(_zaiAdapter);

    SUSDE.approve(ODOS, type(uint256).max);
    ZAI.approve(_zaiAdapter, type(uint256).max);

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(EXECUTOR_ROLE, msg.sender);
  }

  receive() external payable {
    // nothing to do; accept all ETH
  }

  /**
   * @notice Executes a transaction on the ODOS router, distributing revenue to sZAI and MAHA stakers, and the treasury.
   * @param data The transaction data to be executed on the ODOS router.
   */
  function execute(bytes calldata data) public payable onlyRole(EXECUTOR_ROLE) {
    (bool ok,) = ODOS.call{value: msg.value}(data);
    require(ok, "odos call failed");

    uint256 balance = ZAI.balanceOf(address(this));
    emit RevenueCollected(balance);

    // send 70% to sZAI stakers
    uint256 amountsZAI = _calculatePercentage(balance, 7000);
    ZAI.transfer(address(SZAI), amountsZAI);
    emit RevenueDistributed(address(SZAI), amountsZAI);
    emit YieldDistributed(amountsZAI, ZAI.balanceOf(address(SZAI)));

    // send 12.5% to MAHA stakers
    uint256 amountsMAHA = _calculatePercentage(balance, 1250);
    _bridgeToBase(amountsMAHA);
    emit RevenueDistributed(address(OFT_ADAPTER), amountsMAHA);

    // send 12.5% to Buyback and Burn (MM's address)
    uint256 amountsBuyback = _calculatePercentage(balance, 1250);
    ZAI.transfer(mahaBuyback, amountsMAHA);
    emit RevenueDistributed(mahaBuyback, amountsMAHA);

    // rest to treasury
    uint256 amountsTreasury = balance - amountsZAI - amountsMAHA - amountsBuyback;
    ZAI.transfer(treasury, amountsTreasury);
    emit RevenueDistributed(treasury, amountsTreasury);
  }

  /**
   * @notice Sets the destination addresses for cross-chain transfers.
   */
  function setDestinationAddresses(address _treasury, address _mahaBuybacks) external onlyRole(DEFAULT_ADMIN_ROLE) {
    treasury = _treasury;
    mahaBuyback = _mahaBuybacks;
  }

  /**
   * @notice Sends the specified amount of ZAI to base via LayerZero.
   * @param _remoteAddr The destination address on the remote chain.
   * @param _dstEID The destination EID on the remote chain.
   */
  function setLayerZeroDestination(address _remoteAddr, uint32 _dstEID) external onlyRole(DEFAULT_ADMIN_ROLE) {
    remoteDestination = _remoteAddr;
    remoteEID = _dstEID;
  }

  /**
   * @notice Refunds the specified token balance held by the contract to the caller.
   * @dev Only callable by owner of the contract
   * @param token The ERC20 token to be refunded.
   */
  function refund(IERC20 token) external onlyRole(DEFAULT_ADMIN_ROLE) {
    token.safeTransfer(msg.sender, token.balanceOf(address(this)));
  }

  /**
   * @notice Calculates a percentage of a given `amount` based on basis points (bps).
   * @dev The calculation uses basis points, where 10,000 bps = 100%.
   *      Reverts if `amount * bps` is less than 10,000 to prevent overflow issues.
   * @param amount The initial amount to calculate the percentage from.
   * @param bps The basis points (bps) representing the percentage (e.g., 5000 for 50%).
   * @return The calculated percentage of `amount` based on `bps`.
   */
  function _calculatePercentage(uint256 amount, uint256 bps) internal pure returns (uint256) {
    require((amount * bps) >= 10_000, "amount * bps > 10_000");
    return (amount * bps) / 10_000;
  }

  /**
   * @notice Bridges the specified amount of ZAI to the remote chain.
   * @param _amount The amount of ZAI to be bridged.
   */
  function _bridgeToBase(uint256 _amount) internal {
    SendParam memory sendParam = SendParam({
      dstEid: remoteEID,
      to: _addressToBytes32(remoteDestination),
      amountLD: _amount,
      minAmountLD: _amount,
      extraOptions: new bytes(0),
      composeMsg: new bytes(0),
      oftCmd: ""
    });

    MessagingFee memory messagingFee = OFT_ADAPTER.quoteSend(sendParam, false);
    OFT_ADAPTER.send{value: messagingFee.nativeFee}(sendParam, messagingFee, address(this));
  }

  /**
   * @notice Converts an address to a bytes32 format.
   * @dev This is necessary for cross-chain transfers where addresses need to be converted to bytes32.
   * @param _addr The address to convert.
   * @return The converted bytes32 representation of the address.
   */
  function _addressToBytes32(address _addr) internal pure returns (bytes32) {
    return bytes32(uint256(uint160(_addr)));
  }
}
