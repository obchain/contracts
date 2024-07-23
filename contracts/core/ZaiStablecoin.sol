// SPDX-License-Identifier: GPL-3.0

// ███╗   ███╗ █████╗ ██╗  ██╗ █████╗
// ████╗ ████║██╔══██╗██║  ██║██╔══██╗
// ██╔████╔██║███████║███████║███████║
// ██║╚██╔╝██║██╔══██║██╔══██║██╔══██║
// ██║ ╚═╝ ██║██║  ██║██║  ██║██║  ██║
// ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝

// The Stable Money of the Ethermind

// Website: https://maha.xyz
// Discord: https://discord.gg/mahadao
// Twitter: https://twitter.com/mahaxyz_

pragma solidity 0.8.21;

import {IZaiStablecoin} from "../interfaces/IZaiStablecoin.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {ERC20FlashMint} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol";
import {ERC20, ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/**
 * @title Zai Stablecoin "USDz"
 * @author maha.xyz
 * @notice Represents the ZAI stablecoin.
 */
contract ZaiStablecoin is ERC20FlashMint, ERC20Permit, AccessControlEnumerable, IZaiStablecoin {
  /// @inheritdoc IZaiStablecoin
  bytes32 public MANAGER_ROLE = keccak256("MANAGER_ROLE");

  /**
   * Initializes the stablecoin
   */
  constructor() ERC20("Zai Stablecoin", "USDz") ERC20Permit("Zai Stablecoin") {
    _mint(msg.sender, 1e18);
    _burn(msg.sender, 1e18);
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  /// @inheritdoc IZaiStablecoin
  function grantManagerRole(address _account) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _grantRole(MANAGER_ROLE, _account);
  }

  /// @inheritdoc IZaiStablecoin
  function revokeManagerRole(address _account) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _revokeRole(MANAGER_ROLE, _account);
  }

  /// @inheritdoc IZaiStablecoin
  function isManager(address _account) external view returns (bool what) {
    what = hasRole(MANAGER_ROLE, _account);
  }

  /// @inheritdoc IZaiStablecoin
  function mint(address _account, uint256 _amount) external onlyRole(MANAGER_ROLE) {
    _mint(_account, _amount);
  }

  /// @inheritdoc IZaiStablecoin
  function burn(address _account, uint256 _amount) external onlyRole(MANAGER_ROLE) {
    _burn(_account, _amount);
  }
}
