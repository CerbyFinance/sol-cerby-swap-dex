// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.14;

import "./CerbySwapV1_AdminFunctions.sol";
import "./CerbySwapV1_SwapFunctions.sol";

contract CerbySwapV1 is CerbySwapV1_AdminFunctions {

    constructor() {

        _transferOwnership(
            msg.sender
        );

        address mintFeeBeneficiary = 0xdEF78a28c78A461598d948bc0c689ce88f812AD8; // CerbyBridge fees wallet
        uint256 mintFeeMultiplier = MINT_FEE_DENORM * 20 / 100; // means 20% of fees goes to buyback & burn Cerby
        uint256 tvlMultiplier = 1_369_863_014; // 0.1369863014

        uint256 feeMinimum = 1; // 0.01%
        uint256 feeMaximum = 200; // 2.00%

        uint256 tvlMultiplierMinimum = tvlMultiplier; // TVL * 0.1369863014
        uint256 tvlMultiplierMaximum = tvlMultiplier * feeMaximum / feeMinimum; // TVL * 27.397260274

        settings = Settings({
            onePeriodInSeconds: 12 hours,
            mintFeeBeneficiary: mintFeeBeneficiary,
            mintFeeMultiplier: uint32(mintFeeMultiplier),
            feeMinimum: uint8(feeMinimum),
            feeMaximum: uint8(feeMaximum),
            tvlMultiplierMinimum: uint64(tvlMultiplierMinimum),
            tvlMultiplierMaximum: uint64(tvlMultiplierMaximum)
        });

        pools.push(
            Pool({
                sellVolumeThisPeriodInCerby: 0,
                lastCachedFee: 0,
                nextUpdateWillBeAt: 0,
                lastSqrtKValue: 0,
                creditCerby: 0
            })
        );
    }

    receive() external payable {}
}
