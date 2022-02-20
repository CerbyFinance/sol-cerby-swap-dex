// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.12;

import "./CerbySwapV1_EventsAndErrors.sol";

abstract contract CerbySwapV1_Declarations is CerbySwapV1_EventsAndErrors {

    Pool[] pools;

    mapping(address => TokenCache) cachedTokenValues;
    
    address constant CER_USD_TOKEN = 0x3B69b8C5c6a4c8c2a90dc93F3B0238BF70cC9640;
    address constant VAULT_IMPLEMENTATION = 0x029581a9121998fcBb096ceafA92E3E10057878f;
    address constant NATIVE_TOKEN = 0x14769F96e57B80c66837701DE0B43686Fb4632De;


    // address constant NATIVE_TOKEN = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // Ethereum
    // address constant NATIVE_TOKEN = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // BSC
    // address constant NATIVE_TOKEN = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; // Polygon
    // address constant NATIVE_TOKEN = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7; // Avalanche
    // address constant NATIVE_TOKEN = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83; // Fantom

    uint256 constant MINT_FEE_DENORM = 10000;
    uint256 constant MAX_CER_USD_CREDIT = type(uint128).max;

    uint256 constant FEE_DENORM = 10000;
    uint256 constant FEE_DENORM_SQUARED = FEE_DENORM * FEE_DENORM;
    uint256 constant TRADE_VOLUME_DENORM = 1e18;

    uint256 constant TVL_MULTIPLIER_DENORM = 1e10;

    // 6 x 4.8hours + 1 x current 4.8hour = 7 x periods
    uint256 constant NUMBER_OF_TRADE_PERIODS = 6;
    uint256 constant NUMBER_OF_TRADE_PERIODS_MINUS_ONE = NUMBER_OF_TRADE_PERIODS - 1; // equals 5 which is exactly how many periods in 24 hours = 5 * 4.8 hours
    uint256 constant ONE_PERIOD_IN_SECONDS = 288 minutes; // 4.8 hours

    uint256 constant MINIMUM_LIQUIDITY = 1000;
    address constant DEAD_ADDRESS = address(0xdead);

    Settings settings;

    struct TokenCache {
        address vaultAddress;
        uint96 poolId;
    }

    struct Settings {
        address mintFeeBeneficiary;
        uint32 mintFeeMultiplier;
        uint8 feeMinimum;
        uint8 feeMaximum;
        uint64 tvlMultiplierMinimum;
        uint64 tvlMultiplierMaximum;
    }

    struct Pool {
        uint40[NUMBER_OF_TRADE_PERIODS] tradeVolumePerPeriodInCerUsd;
        uint8 lastCachedFee;
        uint8 lastCachedTradePeriod;
        uint128 lastSqrtKValue;
        uint128 creditCerUsd;
    }

    struct PoolBalances {
        uint256 balanceToken;
        uint256 balanceCerUsd;
    }
}
