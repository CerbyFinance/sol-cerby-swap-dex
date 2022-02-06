// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.11;

import "./CerbySwapV1_EventsAndErrors.sol";

abstract contract CerbySwapV1_Declarations is CerbySwapV1_EventsAndErrors {

    Pool[] pools;

    mapping(address => uint256) tokenToPoolId;

    address vaultImplementation;

    address testCerbyToken = 0x527ea24a5917c452DBF402EdC9Da4190239bCcf1; // TODO: remove on production
    address testUsdcToken = 0x947Ef3df5B7D5EC37214Dd06C4042C8E7b0cEBd7; // TODO: remove on production

    address cerUsdToken = 0x46E8e0af862f636199af69aCd082b9963066Ed9C;
    address nativeToken = 0x14769F96e57B80c66837701DE0B43686Fb4632De;

    uint256 constant MINT_FEE_DENORM = 10000;
    uint256 constant MAX_CER_USD_CREDIT = type(uint120).max;

    uint256 constant FEE_DENORM = 10000;
    uint256 constant FEE_DENORM_SQUARED = FEE_DENORM * FEE_DENORM;
    uint256 constant MAX_TRADE_FEE_POSSIBLE = 500; // 5%
    uint256 constant TRADE_VOLUME_DENORM = 1e18;

    uint256 constant TVL_MULTIPLIER_DENORM = 1e10;

    // 6 x 4.8hours + 1 x current 4.8hour = 7 x periods
    uint256 constant NUMBER_OF_TRADE_PERIODS = 6;
    uint256 constant NUMBER_OF_TRADE_PERIODS_MINUS_ONE = NUMBER_OF_TRADE_PERIODS - 1; // equals 5 which is exactly how many periods in 24 hours = 5 * 4.8 hours
    uint256 constant ONE_PERIOD_IN_SECONDS = 288 minutes; // 4.8 hours

    uint256 constant MINIMUM_LIQUIDITY = 1000;
    address constant DEAD_ADDRESS = address(0xdead);

    Settings settings;

    struct Settings {
        address mintFeeBeneficiary;
        uint32 mintFeeMultiplier;
        uint16 feeMinimum;
        uint16 feeMaximum;
        uint64 tvlMultiplierMinimum;
        uint64 tvlMultiplierMaximum;
    }

    struct Pool {
        uint40[NUMBER_OF_TRADE_PERIODS] tradeVolumePerPeriodInCerUsd;
        uint16 lastCachedOneMinusFee;
        uint8 lastCachedTradePeriod;
        uint120 lastSqrtKValue;
        uint120 creditCerUsd;
    }

    struct PoolBalances {
        uint256 balanceToken;
        uint256 balanceCerUsd;
    }
}
