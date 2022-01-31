// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.11;

import "./CerbySwapV1_EventsAndErrors.sol";

abstract contract CerbySwapV1_Declarations is CerbySwapV1_EventsAndErrors {

    Pool[] internal pools;
    mapping(address => uint256) internal tokenToPoolId; // Q: can it be public??
    uint256 internal totalCerUsdBalance;

    address internal testCerbyToken = 0xE7126C0Fb4B1f5F79E5Bbec3948139dCF348B49C; // TODO: remove on production
    address internal cerUsdToken = 0x0fC5025C764cE34df352757e82f7B5c4Df39A836; // TODO: make constant
    address internal testUsdcToken = 0x7412F2cD820d1E63bd130B0FFEBe44c4E5A47d71; // TODO: remove on production
    address internal nativeToken = 0x14769F96e57B80c66837701DE0B43686Fb4632De;

    uint256 internal constant MINT_FEE_DENORM = 100;
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
        uint256 mintFeeMultiplier;
        uint256 feeMinimum;
        uint256 feeMaximum;
        uint256 tvlMultiplierMinimum;
        uint256 tvlMultiplierMaximum;
    }

    struct Pool {
        uint32[NUMBER_OF_TRADE_PERIODS] tradeVolumePerPeriodInCerUsd;
        uint128 balanceToken;
        uint128 balanceCerUsd;
        uint128 lastSqrtKValue;
        uint256 creditCerUsd;
    }
}
