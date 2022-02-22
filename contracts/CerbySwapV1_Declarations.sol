// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.12;

import "./CerbySwapV1_EventsAndErrors.sol";

abstract contract CerbySwapV1_Declarations is CerbySwapV1_EventsAndErrors {

    Pool[] pools;

    mapping(address => TokenCache) cachedTokenValues;

    uint256 constant ETH_MAINNET_CHAIN_ID = 1;
    uint256 constant BSC_MAINNET_CHAIN_ID = 56;
    uint256 constant POLYGON_MAINNET_CHAIN_ID = 137;
    uint256 constant AVALANCHE_MAINNET_CHAIN_ID = 43114;
    uint256 constant FANTOM_MAINNET_CHAIN_ID = 250;
    
    address constant CER_USD_TOKEN = 0x333333f9E4ba7303f1ac0BF8fE1F47d582629194;
    address constant VAULT_IMPLEMENTATION = 0xc0DE7771A6F7029d62E8071e331B36136534D70D;
    address NATIVE_TOKEN;

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
