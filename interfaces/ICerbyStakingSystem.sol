// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.10;

struct DailySnapshot {
    uint inflationAmount;
    uint totalShares;
    uint sharePrice;
}
struct Stake {
    address owner;
    uint stakedAmount;
    uint startDay;
    uint lockedForXDays;
    uint endDay;
    uint maxSharesCountOnStartStake;
}


interface ICerbyStakingSystem {
    function getDailySnapshotsLength()
        external
        view
        returns(uint);

    function getStakesLength()
        external
        view
        returns(uint);

    function getCachedInterestPerShareLength()
        external
        view
        returns(uint);        

    function dailySnapshots(uint pos)
        external
        returns (DailySnapshot memory);        

    function stakes(uint pos)
        external
        returns (Stake memory);        

    function cachedInterestPerShare(uint pos)
        external
        returns (uint);
}