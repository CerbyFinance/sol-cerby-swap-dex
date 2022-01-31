// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.11;

import "./CerbySwapV1_EventsAndErrors.sol";
import "./CerbySwapV1_Declarations_CerUsd.sol";

abstract contract CerbySwapV1_Declarations is
    CerbySwapV1_EventsAndErrors,
    CerbySwapV1_Declarations_CerUsd
{
    Pool[] internal pools;
    mapping(address => uint256) internal tokenToPoolId;
    mapping(address => mapping(uint256 => uint256))
        internal hourlyTradeVolumeInCerUsd;

    address internal testCerbyToken =
        0x527ea24a5917c452DBF402EdC9Da4190239bCcf1; // TODO: remove on production
    address internal testUsdcToken = 0x947Ef3df5B7D5EC37214Dd06C4042C8E7b0cEBd7; // TODO: remove on production

    address internal nativeToken = 0x14769F96e57B80c66837701DE0B43686Fb4632De;

    uint256 internal constant MINT_FEE_DENORM = 100;
    uint128 internal constant MAX_CER_USD_CREDIT = type(uint128).max;

    uint256 internal constant FEE_DENORM = 10000;
    uint256 internal constant FEE_DENORM_SQUARED = FEE_DENORM * FEE_DENORM;
    uint256 internal constant TRADE_VOLUME_DENORM = 10 * 1e18;

    uint256 internal constant TVL_MULTIPLIER_DENORM = 1e10;

    uint256 internal constant ONE_PERIOD_IN_SECONDS = 60 minutes; // 1 hours

    uint256 internal constant MINIMUM_LIQUIDITY = 1000;
    address internal constant DEAD_ADDRESS = address(0xdead);

    Settings internal settings;

    struct Settings {
        address mintFeeBeneficiary;
        uint256 mintFeeMultiplier;
        uint256 feeMinimum;
        uint256 feeMaximum;
        uint256 tvlMultiplierMinimum;
        uint256 tvlMultiplierMaximum;
        uint256 sinceHowManyHoursAgoToTrackTradeVolume;
    }

    struct Pool {
        address vaultAddress;
        uint128 lastSqrtKValue;
        uint128 creditCerUsd;
    }

    struct PoolBalances {
        uint256 balanceToken;
        uint256 balanceCerUsd;
    }
}
