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

import {IOmnichainStaking} from "../../interfaces/governance/IOmnichainStaking.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IMahaLocker {
  function migrateTokenFor(
    uint256 _value,
    uint256 _startDate,
    uint256 _endDate,
    address _who
  ) external returns (uint256);
}

contract MigrateTokenLocks is OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
  bytes32 public merkleRoot;
  IERC20 public maha;
  IMahaLocker public locker;
  IOmnichainStaking public staker;

  mapping(uint256 => bool) public isTokenIdMigrated;
  mapping(uint256 => bool) public isTokenIdBanned;
  mapping(address => bool) public isAddressBanned;

  uint256 internal immutable WEEK = 1 weeks;

  function initialize(
    address _maha,
    address _locker,
    address _governance,
    bytes32 _merkleRoot
  ) external reinitializer(1) {
    __Ownable_init(_governance);
    __ReentrancyGuard_init();
    __Pausable_init();
    maha = IERC20(_maha);
    locker = IMahaLocker(_locker);
    merkleRoot = _merkleRoot;
  }

  function migrateLock(
    uint256 _value,
    uint256 _startDate,
    uint256 _endDate,
    uint256 _tokenId,
    address _who,
    uint256 _mahaReward,
    bytes32[] memory _proof
  ) external returns (uint256) {
    return _migrateLock(_value, _startDate, _endDate, _tokenId, _who, _mahaReward, _proof, false);
  }

  function migrateLockAndStakeBonus(
    uint256 _value,
    uint256 _startDate,
    uint256 _endDate,
    uint256 _tokenId,
    address _who,
    uint256 _mahaReward,
    bytes32[] memory _proof
  ) external returns (uint256) {
    require(_who == msg.sender);
    return _migrateLock(_value, _startDate, _endDate, _tokenId, _who, _mahaReward, _proof, true);
  }

  function migrateLocks(
    uint256[] memory _value,
    uint256[] memory _startDate,
    uint256[] memory _endDate,
    uint256[] memory _tokenId,
    address[] memory _who,
    uint256[] memory _mahaReward,
    bytes32[][] memory proof
  ) external {
    for (uint256 index = 0; index < _value.length; index++) {
      _migrateLock(
        _value[index],
        _startDate[index],
        _endDate[index],
        _tokenId[index],
        _who[index],
        _mahaReward[index],
        proof[index],
        false
      );
    }
  }

  function isLockValid(
    uint256 _value,
    uint256 _startDate,
    uint256 _endDate,
    address _owner,
    uint256 _tokenId,
    uint256 _mahaReward,
    bytes32[] memory proof
  ) public view returns (bool) {
    bytes32 leaf = keccak256(abi.encode(_value, _startDate, _endDate, _owner, _tokenId, _mahaReward));
    return MerkleProof.verify(proof, merkleRoot, leaf);
  }

  function refund() external onlyOwner {
    maha.transfer(msg.sender, maha.balanceOf(address(this)));
  }

  function toggleBanID(uint256 id) external onlyOwner {
    isTokenIdBanned[id] = !isTokenIdBanned[id];
  }

  function togglePause() external onlyOwner {
    if (paused()) _unpause();
    else _pause();
  }

  function toggleBanOwner(address _who) external onlyOwner {
    isAddressBanned[_who] = !isAddressBanned[_who];
  }

  function _migrateLock(
    uint256 _value,
    uint256 _startDate,
    uint256 _endDate,
    uint256 _tokenId,
    address _who,
    uint256 _mahaReward,
    bytes32[] memory proof,
    bool stakeBonus
  ) internal nonReentrant whenNotPaused returns (uint256) {
    require(_endDate >= (block.timestamp + 2 * WEEK), "end date expired");
    require(_tokenId != 0, "tokenId is 0");
    require(!isTokenIdMigrated[_tokenId], "tokenId already migrated");
    require(!isTokenIdBanned[_tokenId], "tokenId banned");
    require(!isAddressBanned[_who], "owner banned");

    bool _isLockvalid = isLockValid(_value, _startDate, _endDate, _who, _tokenId, _mahaReward, proof);
    require(_isLockvalid, "Migrator: invalid lock");

    if (stakeBonus) {
      // if the user wants to stake their rewards also they'll get a 4x bonus
      _value += _mahaReward * 4;
      _endDate = block.timestamp + 1430 days;
      _startDate = block.timestamp;
    } else if (_mahaReward > 0) {
      maha.transfer(_who, _mahaReward);
    }

    uint256 newTokenId = locker.migrateTokenFor(_value, _startDate, _endDate, _who);
    require(newTokenId > 0, "Migrator: migration failed");

    isTokenIdMigrated[_tokenId] = true;
    return newTokenId;
  }
}
