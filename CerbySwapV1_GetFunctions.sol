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

    function _getCurrentPeriod()
        internal
        view
        returns (uint)
    {
        return block.timestamp 
            / ONE_PERIOD_IN_SECONDS
            % NUMBER_OF_TRADE_PERIODS;
    }

    function getCurrentOneMinusFeeBasedOnTrades(address token)
        public
        view
        returns (uint fee)
    {
        // getting pool storage link (saves gas compared to memory)
        Pool storage pool = pools[tokenToPoolId[token]];

        return _getCurrentOneMinusFeeBasedOnTrades(pool);
    }

    function _getCurrentOneMinusFeeBasedOnTrades(Pool storage pool)
        internal
        view
        returns (uint)
    {
        // getting last 24 hours trade volume in USD
        uint currentPeriod = _getCurrentPeriod();
        uint nextPeriod = (currentPeriod + 1) % NUMBER_OF_TRADE_PERIODS;
        uint volume;
        for(uint i; i<NUMBER_OF_TRADE_PERIODS; i++)
        {
            // skipping current and next period because those values are currently updating
            // and are incorrect
            if (i == currentPeriod || i == nextPeriod) continue;

            volume += pool.tradeVolumePerPeriodInCerUsd[i];
        }

        // multiplying it to make wei dimention
        volume = volume * TRADE_VOLUME_DENORM;

        // trades <= TVL * min              ---> fee = feeMaximum
        // TVL * min < trades < TVL * max   ---> fee is between feeMaximum and feeMinimum
        // trades >= TVL * max              ---> fee = feeMinimum
        uint tvlMin = 
            (pool.balanceCerUsd * settings.tvlMultiplierMinimum) / TVL_MULTIPLIER_DENORM;
        uint tvlMax = 
            (pool.balanceCerUsd * settings.tvlMultiplierMaximum) / TVL_MULTIPLIER_DENORM;
        uint fee;
        if (volume <= tvlMin) {
            fee = settings.feeMaximum; // 1.00%
        } else if (tvlMin < volume && volume < tvlMax) {
            fee = 
                settings.feeMaximum - 
                    ((volume - tvlMin) * (settings.feeMaximum - settings.feeMinimum))  / 
                        (tvlMax - tvlMin); // between 1.00% and 0.01%
        } else { // if (volume > tvlMax)
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
            amountTokensOut = _getOutputExactTokensForCerUsd(tokenIn, amountTokensIn);
        } else if (tokenIn == cerUsdToken && tokenOut != cerUsdToken) {

            // getting amountTokensOut
            amountTokensOut = _getOutputExactCerUsdForTokens(tokenOut, amountTokensIn);
        } else if (tokenIn != cerUsdToken && tokenIn != cerUsdToken) {

            // getting amountTokensOut
            uint amountCerUsdOut = _getOutputExactTokensForCerUsd(tokenIn, amountTokensIn);

            amountTokensOut = _getOutputExactCerUsdForTokens(tokenOut, amountCerUsdOut);
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
            amountTokensIn = _getInputTokensForExactCerUsd(tokenIn, amountTokensOut);
        } else if (tokenIn == cerUsdToken && tokenOut != cerUsdToken) {

            // getting amountTokensOut
            amountTokensIn = _getInputCerUsdForExactTokens(tokenOut, amountTokensOut);
        } else if (tokenIn != cerUsdToken && tokenOut != cerUsdToken) {

            // getting amountTokensOut
            uint amountCerUsdOut = _getInputCerUsdForExactTokens(tokenOut, amountTokensOut);

            amountTokensIn = _getInputTokensForExactCerUsd(tokenIn, amountCerUsdOut);
        }
        return amountTokensIn;
    }

    function _getOutputExactTokensForCerUsd(address token, uint amountTokensIn)
        internal
        view
        tokenMustExistInPool(token)
        returns (uint)
    {
        // getting pool storage link (saves gas compared to memory)
        Pool storage pool = pools[tokenToPoolId[token]];

        return _getOutput(
            amountTokensIn,
            uint(pool.balanceToken),
            uint(pool.balanceCerUsd),
            _getCurrentOneMinusFeeBasedOnTrades(pool)
        );
    }

    function _getOutputExactCerUsdForTokens(address token, uint amountCerUsdIn)
        internal
        view
        tokenMustExistInPool(token)
        returns (uint)
    {
        // getting pool storage link (saves gas compared to memory)
        Pool storage pool = pools[tokenToPoolId[token]];

        return _getOutput(
            amountCerUsdIn,
            uint(pool.balanceCerUsd),
            uint(pool.balanceToken),
            //_getCurrentOneMinusFeeBasedOnTrades(pool)
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

    function _getInputTokensForExactCerUsd(address token, uint amountCerUsdOut)
        internal
        view
        tokenMustExistInPool(token)
        returns (uint)
    {
        // getting pool storage link (saves gas compared to memory)
        Pool storage pool = pools[tokenToPoolId[token]];

        return _getInput(
            amountCerUsdOut,
            uint(pool.balanceToken),
            uint(pool.balanceCerUsd),
            _getCurrentOneMinusFeeBasedOnTrades(pool)
        );
    }

    function _getInputCerUsdForExactTokens(address token, uint amountTokensOut)
        internal
        view
        tokenMustExistInPool(token)
        returns (uint)
    {
        // getting pool storage link (saves gas compared to memory)
        Pool storage pool = pools[tokenToPoolId[token]];

        return _getInput(
            amountTokensOut,
            uint(pool.balanceCerUsd),
            uint(pool.balanceToken),
            //_getCurrentOneMinusFeeBasedOnTrades(pool)
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