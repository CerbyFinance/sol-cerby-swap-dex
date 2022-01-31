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

    address internal testCerbyToken =
        0x527ea24a5917c452DBF402EdC9Da4190239bCcf1; // TODO: remove on production
    address internal testUsdcToken = 0x947Ef3df5B7D5EC37214Dd06C4042C8E7b0cEBd7; // TODO: remove on production

    address internal nativeToken = 0x14769F96e57B80c66837701DE0B43686Fb4632De;

    uint256 internal constant MINT_FEE_DENORM = 10000;
    uint256 internal constant MAX_CER_USD_CREDIT = type(uint128).max;

    uint256 internal constant FEE_DENORM = 10000;
    uint256 internal constant FEE_DENORM_SQUARED = FEE_DENORM * FEE_DENORM;
    uint256 internal constant TRADE_VOLUME_DENORM = 10 * 1e18;

    uint256 internal constant TVL_MULTIPLIER_DENORM = 1e10;

    // 6 4hours + 1 current 4hour + 1 next 4hour = 8 hours
    uint256 internal constant NUMBER_OF_TRADE_PERIODS = 8;
    uint256 internal constant ONE_PERIOD_IN_SECONDS = 240 minutes; // 4 hours

    uint256 internal constant MINIMUM_LIQUIDITY = 1000;
    address internal constant DEAD_ADDRESS = address(0xdead);

    Settings internal settings;

    struct Settings {
        address mintFeeBeneficiary;
        uint32 mintFeeMultiplier;
        uint16 feeMinimum;
        uint16 feeMaximum;
        uint64 tvlMultiplierMinimum;
        uint64 tvlMultiplierMaximum;
    }

    struct Pool {
        address vaultAddress;
        uint32[NUMBER_OF_TRADE_PERIODS] tradeVolumePerPeriodInCerUsd;
        uint8 lastCachedTradePeriod;
        uint16 lastCachedOneMinusFee;
        uint128 lastSqrtKValue;
        uint128 creditCerUsd;
    }

    struct PoolBalances {
        uint256 balanceToken;
        uint256 balanceCerUsd;
    }
}
