// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.11;


struct Pool {
    uint32[8] tradeVolumePerPeriodInCerUsd;
    uint128 balanceToken;
    uint128 balanceCerUsd;
    uint128 lastSqrtKValue;
}

interface ICerbySwapV1 {

    function getCurrentFeeBasedOnTrades(address token)
        external
        view
        returns (uint fee);

    function getPoolsByTokens(address[] calldata tokens)
        external
        view
        returns (Pool[] memory);

    function addTokenLiquidity(
        address token, 
        uint amountTokensIn, 
        uint expireTimestamp,
        address transferTo
    )
        external
        payable
        returns (uint);

    function removeTokenLiquidity(
        address token, 
        uint amountLpTokensBalanceToBurn, 
        uint expireTimestamp,
        address transferTo
    )
        external
        returns (uint);

    function swapExactTokensForTokens(
        address tokenIn,
        address tokenOut,
        uint amountTokensIn,
        uint minAmountTokensOut,
        uint expireTimestamp,
        address transferTo
    )
        external
        payable
        returns (uint, uint);

    function getInputTokensForExactTokens(
        address tokenIn,
        address tokenOut,
        uint amountTokensOut
    )
        external
        view
        returns (uint amountTokensIn);

    function getOutputExactTokensForTokens(
        address tokenIn,
        address tokenOut,
        uint amountTokensIn
    )
        external
        view
        returns (uint amountTokensOut);
}