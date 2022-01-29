// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.11;

import "./CerbySwapV1_AdminFunctions.sol";
import "./CerbySwapV1_SwapFunctions.sol";


contract CerbySwapV1 is 
    CerbySwapV1_AdminFunctions, CerbySwapV1_SwapFunctions
{
    constructor() {        
        _transferOwnership(msg.sender);

        address mintFeeBeneficiary = 0xdEF78a28c78A461598d948bc0c689ce88f812AD8; // CerbyBridge fees wallet
        uint mintFeeMultiplier = (MINT_FEE_DENORM * 20) / 100; // means 20% of fees goes to buyback & burn Cerby
        uint tvlMultiplier = 1369863014; // 0.1369863014
        uint feeMinimum = 1; // 0.01%
        uint feeMaximum = 200; // 2.00%
        uint tvlMultiplierMinimum = tvlMultiplier; // TVL * 0.1369863014
        uint tvlMultiplierMaximum = (tvlMultiplier * feeMaximum) / feeMinimum; // TVL * 27.397260274
        settings = Settings(
            mintFeeBeneficiary,
            mintFeeMultiplier,
            feeMinimum,
            feeMaximum,
            tvlMultiplierMinimum,
            tvlMultiplierMaximum
        );

        // Filling with empty pool 0th id
        uint32[NUMBER_OF_TRADE_PERIODS] memory tradeVolumePerPeriodInCerUsd;
        pools.push(Pool(
            tradeVolumePerPeriodInCerUsd,
            0,
            0,
            0,
            0
        ));

        if (block.chainid == 1) { // Ethereum
            nativeToken = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        } else if (block.chainid == 56) { // BSC
            nativeToken = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        } else if (block.chainid == 137) { // Polygon
            nativeToken = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
        } else if (block.chainid == 43114) { // Avalanche
            nativeToken = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
        } else if (block.chainid == 250) { // Fantom
            nativeToken = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
        }

        // testnet native token
        nativeToken = 0x14769F96e57B80c66837701DE0B43686Fb4632De; // TODO: update

    }

    receive() external payable {}


    




}