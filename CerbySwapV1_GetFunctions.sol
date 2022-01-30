// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.11;

import "./CerbySwapV1_Modifiers.sol";

abstract contract CerbySwapV1_GetFunctions is CerbySwapV1_Modifiers {
    function getTokenToPoolId(address token) public view returns (uint256) {
        return tokenToPoolId[token];
    }

    function getSettings() public view returns (Settings memory) {
        return settings;
    }

    function _getCurrentPeriod() internal view returns (uint256) {
        return
            (block.timestamp / ONE_PERIOD_IN_SECONDS) % NUMBER_OF_TRADE_PERIODS;
    }

    function getCurrentOneMinusFeeBasedOnTrades(address token)
        public
        view
        returns (uint256 fee)
    {
        // getting pool storage link (saves gas compared to memory)
        Pool storage pool = pools[tokenToPoolId[token]];

        return _getCurrentOneMinusFeeBasedOnTrades(pool);
    }

    function _getCurrentOneMinusFeeBasedOnTrades(Pool storage pool)
        internal
        view
        returns (uint256)
    {
        // getting last 24 hours trade volume in USD
        uint256 currentPeriod = _getCurrentPeriod();
        uint256 nextPeriod = (currentPeriod + 1) % NUMBER_OF_TRADE_PERIODS;
        uint256 volume;
        for (uint256 i; i < NUMBER_OF_TRADE_PERIODS; i++) {
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
        uint256 tvlMin = (pool.balanceCerUsd * settings.tvlMultiplierMinimum) /
            TVL_MULTIPLIER_DENORM;
        uint256 tvlMax = (pool.balanceCerUsd * settings.tvlMultiplierMaximum) /
            TVL_MULTIPLIER_DENORM;
        uint256 fee;
        if (volume <= tvlMin) {
            fee = settings.feeMaximum; // 1.00%
        } else if (tvlMin < volume && volume < tvlMax) {
            fee =
                settings.feeMaximum -
                ((volume - tvlMin) *
                    (settings.feeMaximum - settings.feeMinimum)) /
                (tvlMax - tvlMin); // between 1.00% and 0.01%
        } else {
            // if (volume > tvlMax)
            fee = settings.feeMinimum; // 0.01%
        }

        // returning oneMinusFee = 1 - fee for further calculations
        return FEE_DENORM - fee;
    }

    function getOutputExactTokensForTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountTokensIn
    ) public view returns (uint256) {
        uint256 amountTokensOut;

        // direction XXX --> cerUSD
        if (tokenIn != cerUsdToken && tokenOut == cerUsdToken) {
            // getting amountTokensOut
            amountTokensOut = _getOutputExactTokensForCerUsd(
                tokenIn,
                amountTokensIn
            );
            return amountTokensOut;
        }

        // direction cerUSD --> YYY
        if (tokenIn == cerUsdToken && tokenOut != cerUsdToken) {
            // getting amountTokensOut
            amountTokensOut = _getOutputExactCerUsdForTokens(
                tokenOut,
                amountTokensIn
            );
            return amountTokensOut;
        }

        // tokenIn != cerUsdToken && tokenIn != cerUsdToken clause
        // direction XXX --> cerUSD --> YYY (or XXX --> YYY)
        // getting amountTokensOut
        uint256 amountCerUsdOut = _getOutputExactTokensForCerUsd(
            tokenIn,
            amountTokensIn
        );

        amountTokensOut = _getOutputExactCerUsdForTokens(
            tokenOut,
            amountCerUsdOut
        );
        return amountTokensOut;
    }

    function getInputTokensForExactTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountTokensOut
    ) public view returns (uint256) {
        uint256 amountTokensIn;

        // direction XXX --> cerUSD
        if (tokenIn != cerUsdToken && tokenOut == cerUsdToken) {
            // getting amountTokensOut
            amountTokensIn = _getInputTokensForExactCerUsd(
                tokenIn,
                amountTokensOut
            );
            return amountTokensIn;
        }

        // direction cerUSD --> YYY
        if (tokenIn == cerUsdToken && tokenOut != cerUsdToken) {
            // getting amountTokensOut
            amountTokensIn = _getInputCerUsdForExactTokens(
                tokenOut,
                amountTokensOut
            );
            return amountTokensIn;
        }

        // tokenIn != cerUsdToken && tokenIn != cerUsdToken clause
        // direction XXX --> cerUSD --> YYY (or XXX --> YYY)
        // getting amountTokensOut
        uint256 amountCerUsdOut = _getInputCerUsdForExactTokens(
            tokenOut,
            amountTokensOut
        );

        amountTokensIn = _getInputTokensForExactCerUsd(
            tokenIn,
            amountCerUsdOut
        );
        return amountTokensIn;
    }

    function _getOutputExactTokensForCerUsd(
        address token,
        uint256 amountTokensIn
    ) internal view tokenMustExistInPool(token) returns (uint256) {
        // getting pool storage link (saves gas compared to memory)
        Pool storage pool = pools[tokenToPoolId[token]];

        return
            _getOutput(
                amountTokensIn,
                uint256(pool.balanceToken),
                uint256(pool.balanceCerUsd),
                _getCurrentOneMinusFeeBasedOnTrades(pool)
            );
    }

    function _getOutputExactCerUsdForTokens(
        address token,
        uint256 amountCerUsdIn
    ) internal view tokenMustExistInPool(token) returns (uint256) {
        // getting pool storage link (saves gas compared to memory)
        Pool storage pool = pools[tokenToPoolId[token]];

        return
            _getOutput(
                amountCerUsdIn,
                uint256(pool.balanceCerUsd),
                uint256(pool.balanceToken),
                //_getCurrentOneMinusFeeBasedOnTrades(pool)
                FEE_DENORM // fee is zero for swaps cerUsd --> Any (oneMinusFee = FEE_DENORM)
            );
    }

    function _getOutput(
        uint256 amountIn,
        uint256 reservesIn,
        uint256 reservesOut,
        uint256 oneMinusFee
    ) internal pure returns (uint256) {
        // refer to https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol
        uint256 amountInWithFee = amountIn * oneMinusFee;
        uint256 amountOut = (reservesOut * amountInWithFee) /
            (reservesIn * FEE_DENORM + amountInWithFee);
        return amountOut;
    }

    function _getInputTokensForExactCerUsd(
        address token,
        uint256 amountCerUsdOut
    ) internal view tokenMustExistInPool(token) returns (uint256) {
        // getting pool storage link (saves gas compared to memory)
        Pool storage pool = pools[tokenToPoolId[token]];

        return
            _getInput(
                amountCerUsdOut,
                uint256(pool.balanceToken),
                uint256(pool.balanceCerUsd),
                _getCurrentOneMinusFeeBasedOnTrades(pool)
            );
    }

    function _getInputCerUsdForExactTokens(
        address token,
        uint256 amountTokensOut
    ) internal view tokenMustExistInPool(token) returns (uint256) {
        // getting pool storage link (saves gas compared to memory)
        Pool storage pool = pools[tokenToPoolId[token]];

        return
            _getInput(
                amountTokensOut,
                uint256(pool.balanceCerUsd),
                uint256(pool.balanceToken),
                FEE_DENORM // fee is zero for swaps cerUsd --> Any (oneMinusFee = FEE_DENORM)
            );
    }

    function _getInput(
        uint256 amountOut,
        uint256 reservesIn,
        uint256 reservesOut,
        uint256 oneMinusFee
    ) internal pure returns (uint256) {
        // refer to https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol
        uint256 amountIn = (reservesIn * amountOut * FEE_DENORM) /
            (oneMinusFee * (reservesOut - amountOut)) +
            1; // adding +1 for any rounding trims
        return amountIn;
    }

    function getPoolsByIds(uint256[] calldata ids)
        public
        view
        returns (Pool[] memory)
    {
        Pool[] memory outputPools = new Pool[](ids.length);
        for (uint256 i; i < ids.length; i++) {
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
        for (uint256 i; i < tokens.length; i++) {
            outputPools[i] = pools[tokenToPoolId[tokens[i]]];
        }
        return outputPools;
    }
}
