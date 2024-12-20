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

import {IAggregatorV3Interface} from "../../interfaces/governance/IAggregatorV3Interface.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

contract BalancesUIHelper {
  address constant MOCK_ETH_ADDRESS = 0x0000000000000000000000000000000000000000;

  function balanceOf(address user, address token) public view returns (uint256) {
    if (token == MOCK_ETH_ADDRESS) return user.balance;
    return IERC20(token).balanceOf(user);
  }

  function batchBalanceOfCross(
    address[] calldata users,
    address[] calldata tokens
  ) external view returns (uint256[] memory balances) {
    balances = new uint256[](users.length * tokens.length);

    for (uint256 i = 0; i < users.length; i++) {
      for (uint256 j = 0; j < tokens.length; j++) {
        balances[i * tokens.length + j] = balanceOf(users[i], tokens[j]);
      }
    }
  }

  function batchBalanceOfSingle(
    address[] calldata users,
    address[] calldata tokens
  ) external view returns (uint256[] memory balances) {
    balances = new uint256[](users.length);

    for (uint256 i = 0; i < users.length; i++) {
      balances[i] = balanceOf(users[i], tokens[i]);
    }
  }

  function batchDetailsOf(
    address[] calldata tokens,
    address[] calldata chainlinkOracles
  )
    external
    view
    returns (
      string[] memory names,
      string[] memory symbols,
      uint8[] memory decimals,
      uint256[] memory totalSupplies,
      int256[] memory prices
    )
  {
    names = new string[](tokens.length);
    symbols = new string[](tokens.length);
    decimals = new uint8[](tokens.length);
    prices = new int256[](tokens.length);
    totalSupplies = new uint256[](tokens.length);

    for (uint256 i = 0; i < tokens.length; i++) {
      if (tokens[i] == MOCK_ETH_ADDRESS) {
        names[i] = "Ethereum";
        symbols[i] = "ETH";
        decimals[i] = 18;
        totalSupplies[i] = 100_000 ether;
        prices[i] = IAggregatorV3Interface(chainlinkOracles[i]).latestAnswer();
        continue;
      }

      names[i] = IERC20Metadata(tokens[i]).name();
      symbols[i] = IERC20Metadata(tokens[i]).symbol();
      decimals[i] = IERC20Metadata(tokens[i]).decimals();
      totalSupplies[i] = IERC20(tokens[i]).totalSupply();
      prices[i] = IAggregatorV3Interface(chainlinkOracles[i]).latestAnswer();
    }
  }

  function batchAllowancesOf(
    address[] calldata users,
    address[] calldata targets,
    address[] calldata tokens
  ) external view returns (uint256[] memory allowances) {
    allowances = new uint256[](users.length);
    for (uint256 i = 0; i < users.length; i++) {
      allowances[i] = IERC20(tokens[i]).allowance(users[i], targets[i]);
    }
  }
}
