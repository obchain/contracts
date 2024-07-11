// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.6;

interface IRewardBase {
    function incentivesLength() external view returns (uint);

    // returns the last time the reward was modified or periodFinish if the reward has ended
    function lastTimeRewardApplicable(
        address token
    ) external view returns (uint);

    // how to calculate the reward given per token "staked" (or voted for bribes)
    function rewardPerToken(address token) external view returns (uint);

    // how to calculate the total earnings of an address for a given token
    function earned(
        address token,
        address account
    ) external view returns (uint);

    // total amount of rewards returned for the 7 day duration
    function getRewardForDuration(address token) external view returns (uint);

    // allows a user to claim rewards for a given token
    function getReward(address token) external;

    // used to notify a gauge/bribe of a given reward, this can create griefing attacks by extending rewards
    // TODO: rework to weekly resets, _updatePeriod as per v1 bribes
    function notifyRewardAmount(
        address token,
        uint amount
    ) external returns (bool);
}

// Gauges are used to incentivize pools, they emit reward tokens over 7 days for staked LP tokens
// Nuance: getReward must be called at least once for tokens other than incentive[0] to start accrueing rewards
interface IGauge is IRewardBase {
    function rewardPerToken(
        address token
    ) external view override returns (uint);

    // used to update an account internally and externally, since ve decays over times, an address could have 0 balance but still register here
    function kick(address account) external;

    function derivedBalance(address account) external view returns (uint);

    function earned(
        address token,
        address account
    ) external view override returns (uint);

    function deposit(uint amount, address account) external;

    function withdraw() external;

    function withdraw(uint amount) external;

    function exit() external;
}
