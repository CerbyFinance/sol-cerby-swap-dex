// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.11;

import "./CerbySwapV1_Modifiers.sol";

abstract contract CerbySwapV1_GetFunctions is CerbySwapV1_Modifiers {


    function getTokenToPoolId(address token) 
        public
        view
        returns (uint)
    {
        return tokenToPoolId[token];
    }

    function getSettings() 
        public
        view
        returns (Settings memory)
    {
        return settings;
    }

    function getCurrentPeriod()
        internal
        view
        returns (uint)
    {
        return (block.timestamp / ONE_PERIOD_IN_SECONDS) % NUMBER_OF_TRADE_PERIODS;
    }

    function getCurrentOneMinusFeeBasedOnTrades(address token)
        public
        view
        returns (uint fee)
    {
        return _getCurrentOneMinusFeeBasedOnTrades(tokenToPoolId[token]);
    }

    function _getCurrentOneMinusFeeBasedOnTrades(uint poolId)
        internal
        view
        returns (uint)
    {
        // getting last 24 hours trade volume in USD
        uint currentPeriod = getCurrentPeriod();
        uint nextPeriod = (currentPeriod + 1) % NUMBER_OF_TRADE_PERIODS;
        uint volume;
        for(uint i; i<NUMBER_OF_TRADE_PERIODS; i++)
        {
            // skipping current and next period because those values are currently updating
            // and are incorrect
            if (i == currentPeriod || i == nextPeriod) continue;

            volume += pools[poolId].tradeVolumePerPeriodInCerUsd[i];
        }

        // multiplying it to make wei dimention
        volume = volume * TRADE_VOLUME_DENORM;

        // trades <= TVL * min              ---> fee = feeMaximum
        // TVL * min < trades < TVL * max   ---> fee is between feeMaximum and feeMinimum
        // trades >= TVL * max              ---> fee = feeMinimum
        uint tvlMin = 
            (pools[poolId].balanceCerUsd * settings.tvlMultiplierMinimum) / TVL_MULTIPLIER_DENORM;
        uint tvlMax = 
            (pools[poolId].balanceCerUsd * settings.tvlMultiplierMaximum) / TVL_MULTIPLIER_DENORM;
        uint fee;
        if (volume <= tvlMin) {
            fee = settings.feeMaximum; // 1.00%
        } else if (tvlMin < volume && volume < tvlMax) {
            fee = 
                settings.feeMaximum - 
                    ((volume - tvlMin) * (settings.feeMaximum - settings.feeMinimum))  / 
                        (tvlMax - tvlMin); // between 1.00% and 0.01%
        } else if (volume > tvlMax) {
            fee = settings.feeMinimum; // 0.01%
        }

        // returning oneMinusFee = 1 - fee for further calculations
        return FEE_DENORM - fee;
    }

    function getOutputExactTokensForTokens(
        address tokenIn,
        address tokenOut,
        uint amountTokensIn
    )
        public
        view
        returns (uint amountTokensOut)
    {
        if (tokenIn != cerUsdToken && tokenOut == cerUsdToken) {

            // getting amountTokensOut
            amountTokensOut = getOutputExactTokensForCerUsd(tokenIn, amountTokensIn);
        } else if (tokenIn == cerUsdToken && tokenOut != cerUsdToken) {

            // getting amountTokensOut
            amountTokensOut = getOutputExactCerUsdForTokens(tokenOut, amountTokensIn);
        } else if (tokenIn != cerUsdToken && tokenIn != cerUsdToken) {

            // getting amountTokensOut
            uint amountCerUsdOut = getOutputExactTokensForCerUsd(tokenIn, amountTokensIn);

            amountTokensOut = getOutputExactCerUsdForTokens(tokenOut, amountCerUsdOut);
        }
        return amountTokensOut;
    }

    function getInputTokensForExactTokens(
        address tokenIn,
        address tokenOut,
        uint amountTokensOut
    )
        public
        view
        returns (uint amountTokensIn)
    {
        if (tokenIn != cerUsdToken && tokenOut == cerUsdToken) {

            // getting amountTokensOut
            amountTokensIn = getInputTokensForExactCerUsd(tokenIn, amountTokensOut);
        } else if (tokenIn == cerUsdToken && tokenOut != cerUsdToken) {

            // getting amountTokensOut
            amountTokensIn = getInputCerUsdForExactTokens(tokenOut, amountTokensOut);
        } else if (tokenIn != cerUsdToken && tokenOut != cerUsdToken) {

            // getting amountTokensOut
            uint amountCerUsdOut = getInputCerUsdForExactTokens(tokenOut, amountTokensOut);

            amountTokensIn = getInputTokensForExactCerUsd(tokenIn, amountCerUsdOut);
        }
        return amountTokensIn;
    }

    function getOutputExactTokensForCerUsd(address token, uint amountTokensIn)
        internal
        view
        tokenMustExistInPool(token)
        returns (uint)
    {
        uint poolId = tokenToPoolId[token];
        return _getOutput(
            amountTokensIn,
            uint(pools[poolId].balanceToken),
            uint(pools[poolId].balanceCerUsd),
            _getCurrentOneMinusFeeBasedOnTrades(poolId)
        );
    }

    function getOutputExactCerUsdForTokens(address token, uint amountCerUsdIn)
        internal
        view
        tokenMustExistInPool(token)
        returns (uint)
    {
        uint poolId = tokenToPoolId[token];
        return _getOutput(
            amountCerUsdIn,
            uint(pools[poolId].balanceCerUsd),
            uint(pools[poolId].balanceToken),
            //_getCurrentOneMinusFeeBasedOnTrades(poolId)
            FEE_DENORM // fee is zero for swaps cerUsd --> Any (oneMinusFee = FEE_DENORM)
        );
    }

    function _getOutput(uint amountIn, uint reservesIn, uint reservesOut, uint oneMinusFee)
        internal
        pure
        returns (uint)
    {
        uint amountInWithFee = amountIn * oneMinusFee;
        uint amountOut = 
            (reservesOut * amountInWithFee) / (reservesIn * FEE_DENORM + amountInWithFee);
        return amountOut;
    }

    function getInputTokensForExactCerUsd(address token, uint amountCerUsdOut)
        internal
        view
        tokenMustExistInPool(token)
        returns (uint)
    {
        uint poolId = tokenToPoolId[token];
        return _getInput(
            amountCerUsdOut,
            uint(pools[poolId].balanceToken),
            uint(pools[poolId].balanceCerUsd),
            _getCurrentOneMinusFeeBasedOnTrades(poolId)
        );
    }

    function getInputCerUsdForExactTokens(address token, uint amountTokensOut)
        internal
        view
        tokenMustExistInPool(token)
        returns (uint)
    {
        uint poolId = tokenToPoolId[token];
        return _getInput(
            amountTokensOut,
            uint(pools[poolId].balanceCerUsd),
            uint(pools[poolId].balanceToken),
            //_getCurrentOneMinusFeeBasedOnTrades(poolId)
            FEE_DENORM // fee is zero for swaps cerUsd --> Any (oneMinusFee = FEE_DENORM)
        );
    }

    function _getInput(uint amountOut, uint reservesIn, uint reservesOut, uint oneMinusFee)
        internal
        pure
        returns (uint)
    {
        uint amountIn = (reservesIn * amountOut * FEE_DENORM) /
            (oneMinusFee * (reservesOut - amountOut)) + 1; // adding +1 for any rounding trims
        return amountIn;
    }

    function getPoolsByIds(uint[] calldata ids)
        public
        view
        returns (Pool[] memory)
    {
        Pool[] memory outputPools = new Pool[](ids.length);
        for(uint i; i<ids.length; i++) {
            outputPools[i] = pools[ids[i]];
        }
        return outputPools;
    }

    function getPoolsByTokens(address[] calldata tokens)
        public
        view
        returns (Pool[] memory)
    {
        Pool[] memory outputPools = new Pool[](tokens.length);
        for(uint i; i<tokens.length; i++) {
            outputPools[i] = pools[tokenToPoolId[tokens[i]]];
        }
        return outputPools;
    }
}