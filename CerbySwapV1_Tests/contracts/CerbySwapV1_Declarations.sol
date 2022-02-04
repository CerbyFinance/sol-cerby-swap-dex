// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.11;

import "./CerbySwapV1_EventsAndErrors.sol";

abstract contract CerbySwapV1_Declarations is CerbySwapV1_EventsAndErrors {

    // Q: internal?

    Pool[] pools; // Q: everything by default is

    mapping(address => uint256) tokenToPoolId;

    address vaultImplementation;

    address testCerbyToken = 0x527ea24a5917c452DBF402EdC9Da4190239bCcf1; // TODO: remove on production
    address testUsdcToken = 0x947Ef3df5B7D5EC37214Dd06C4042C8E7b0cEBd7; // TODO: remove on production

    address cerUsdToken = 0x46E8e0af862f636199af69aCd082b9963066Ed9C; // Q: is this upgradable? (use constant or immutable)
    address nativeToken = 0x14769F96e57B80c66837701DE0B43686Fb4632De; // Q: is this upgradable? (use constant or immutable)

    uint256 constant MINT_FEE_DENORM = 10000;
    uint256 constant MAX_CER_USD_CREDIT = type(uint112).max;

    uint256 constant FEE_DENORM = 10000;
    uint256 constant FEE_DENORM_SQUARED = FEE_DENORM * FEE_DENORM;
    uint256 constant TRADE_VOLUME_DENORM = 10 * 1e18;

    uint256 constant TVL_MULTIPLIER_DENORM = 1e10;

    // 6 4hours + 1 current 4hour + 1 next 4hour = 8 hours
    uint256 constant NUMBER_OF_TRADE_PERIODS = 8;
    uint256 constant ONE_PERIOD_IN_SECONDS = 4 hours; // 4 hours

    uint256 constant MINIMUM_LIQUIDITY = 1000;
    address constant DEAD_ADDRESS = address(0xdead); // why not address(0)?

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
        uint32[NUMBER_OF_TRADE_PERIODS] tradeVolumePerPeriodInCerUsd;
        uint8 lastCachedTradePeriod;
        uint16 lastCachedOneMinusFee;
        uint112 lastSqrtKValue;
        uint112 creditCerUsd;
    }

    struct PoolBalances {
        uint256 balanceToken;
        uint256 balanceCerUsd;
    }
}
