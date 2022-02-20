// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.12;

import "./CerbySwapV1_Modifiers.sol";
import "./CerbySwapV1_SafeFunctions.sol";

abstract contract CerbySwapV1_GetFunctions is
    CerbySwapV1_Modifiers,
    CerbySwapV1_SafeFunctions
{
    function getTokenToPoolId(
        address _token
    )
        external
        view
        returns (uint256)
    {
        return cachedTokenValues[_token].poolId;
    }

    function getSettings()
        external
        view
        returns (Settings memory)
    {
        return settings;
    }

    function getPoolsByTokens(
        address[] calldata _tokens
    )
        external
        view
        returns (Pool[] memory)
    {
        Pool[] memory outputPools = new Pool[](_tokens.length);
        for (uint256 i; i < _tokens.length; i++) {
            address token = _tokens[i];
            outputPools[i] = pools[cachedTokenValues[token].poolId];
        }
        return outputPools;
    }

    function getPoolsBalancesByTokens(
        address[] calldata _tokens
    )
        external
        view
        returns (PoolBalances[] memory)
    {
        PoolBalances[] memory outputPools = new PoolBalances[](_tokens.length);
        for (uint256 i; i < _tokens.length; i++) {
            address token = _tokens[i];
            outputPools[i] = _getPoolBalances(token);
        }
        return outputPools;
    }

    function getCurrentFeeBasedOnTrades(
        address _token
    )
        external
        view
        returns (uint256 fee)
    {
        // getting pool storage link (saves gas compared to memory)
        Pool storage pool = pools[cachedTokenValues[_token].poolId];

        PoolBalances memory poolBalances = _getPoolBalances(
            _token
        );

        return _getCurrentFeeBasedOnTrades(
            pool,
            poolBalances
        );
    }

    function getOutputExactTokensForTokens(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountTokensIn
    )
        external
        view
        returns (uint256)
    {
        // caller responsibility to provide
        // _tokenIn != _tokenOut

        // direction XXX --> cerUSD
        if (_tokenOut == CER_USD_TOKEN) {
            // getting amountTokensOut
            return _getOutputExactTokensForCerUsd(
                _getPoolBalances(_tokenIn),
                _tokenIn,
                _amountTokensIn
            );
        }

        // direction cerUSD --> YYY
        if (_tokenIn == CER_USD_TOKEN) {
            // getting amountTokensOut
            return _getOutputExactCerUsdForTokens(
                _getPoolBalances(_tokenOut),
                _amountTokensIn
            );
        }

        // tokenIn != CER_USD_TOKEN && tokenIn != CER_USD_TOKEN clause
        // direction XXX --> cerUSD --> YYY (or XXX --> YYY)
        // getting amountTokensOut
        uint256 amountCerUsdOut = _getOutputExactTokensForCerUsd(
            _getPoolBalances(_tokenIn),
            _tokenIn,
            _amountTokensIn
        );

        return _getOutputExactCerUsdForTokens(
            _getPoolBalances(_tokenOut),
            amountCerUsdOut
        );
    }

    function getInputTokensForExactTokens(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountTokensOut
    )
        external
        view
        returns (uint256)
    {
        // caller responsibility to provide
        // _tokenIn != _tokenOut

        // direction XXX --> cerUSD
        if (_tokenOut == CER_USD_TOKEN) {
            // getting amountTokensOut
            return _getInputTokensForExactCerUsd(
                _getPoolBalances(_tokenIn),
                _tokenIn,
                _amountTokensOut
            );
        }

        // direction cerUSD --> YYY
        if (_tokenIn == CER_USD_TOKEN) {
            // getting amountTokensOut
            return _getInputCerUsdForExactTokens(
                _getPoolBalances(_tokenOut),
                _amountTokensOut
            );
        }

        // tokenIn != CER_USD_TOKEN && tokenIn != CER_USD_TOKEN clause
        // direction XXX --> cerUSD --> YYY (or XXX --> YYY)
        // getting amountTokensOut
        uint256 amountCerUsdOut = _getInputCerUsdForExactTokens(
            _getPoolBalances(_tokenOut),
            _amountTokensOut
        );

        return _getInputTokensForExactCerUsd(
            _getPoolBalances(_tokenIn),
            _tokenIn,
            amountCerUsdOut
        );
    }

    function _getCurrentPeriod()
        internal
        view
        returns (uint256)
    {
        return block.timestamp
            / ONE_PERIOD_IN_SECONDS
            % NUMBER_OF_TRADE_PERIODS;
    }

    function _getCurrentFeeBasedOnTrades(
        Pool storage _pool,
        PoolBalances memory _poolBalances
    )
        internal
        view
        returns (uint256)
    {
        // getting last 24 hours trade volume in USD
        uint256 currentPeriod = _getCurrentPeriod();
        uint256 volume;

        for (uint256 i; i < NUMBER_OF_TRADE_PERIODS; i++) {
            // skipping current because this value is currently updating
            // and must be skipped
            if (i == currentPeriod) continue;
            volume += _pool.tradeVolumePerPeriodInCerUsd[i];
        }

        // substracting 5 because in _swap function
        // because if there are no trades we fill values with 1
        // multiplying it to make wei dimention
        volume = (volume - NUMBER_OF_TRADE_PERIODS_MINUS_ONE) * TRADE_VOLUME_DENORM;

        // trades <= TVL * min              ---> fee = feeMaximum
        // TVL * min < trades < TVL * max   ---> fee is between feeMaximum and feeMinimum
        // trades >= TVL * max              ---> fee = feeMinimum
        uint256 tvlMin = _poolBalances.balanceCerUsd
            * uint256(settings.tvlMultiplierMinimum)
            / TVL_MULTIPLIER_DENORM;

        uint256 tvlMax = _poolBalances.balanceCerUsd
            * uint256(settings.tvlMultiplierMaximum)
            / TVL_MULTIPLIER_DENORM;

        if (volume <= tvlMin) {
            return uint256(settings.feeMaximum); // fee is maximum
        }

        if (volume >= tvlMax) {
            return uint256(settings.feeMinimum); // fee is minimum
        }

        return uint256(settings.feeMaximum)
            - (uint256(settings.feeMaximum) - uint256(settings.feeMinimum))
            * (volume - tvlMin)
            / (tvlMax - tvlMin); // fee is between minimum and maximum
    }

    function _getOutputExactTokensForCerUsd(
        PoolBalances memory poolBalances,
        address _token,
        uint256 _amountTokensIn
    )
        internal
        view
        returns (uint256)
    {
        // getting pool storage link (saves gas compared to memory)
        Pool storage pool = pools[cachedTokenValues[_token].poolId];

        return _getOutput(
            _amountTokensIn,
            uint256(poolBalances.balanceToken),
            uint256(poolBalances.balanceCerUsd),
            _getCurrentFeeBasedOnTrades(
                pool,
                poolBalances
            )
        );
    }

    function _getOutputExactCerUsdForTokens(
        PoolBalances memory poolBalances,
        uint256 _amountCerUsdIn
    )
        internal
        pure
        returns (uint256)
    {
        return _getOutput(
            _amountCerUsdIn,
            uint256(poolBalances.balanceCerUsd),
            uint256(poolBalances.balanceToken),
            0 // fee is zero for swaps cerUsd --> Any
        );
    }

    function _getOutput(
        uint256 _amountIn,
        uint256 _reservesIn,
        uint256 _reservesOut,
        uint256 _fee
    )
        internal
        pure
        returns (uint256)
    {
        // refer to https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol
        uint256 amountInWithFee = _amountIn
            * (FEE_DENORM - _fee);

        return amountInWithFee
            * _reservesOut
            / (_reservesIn * FEE_DENORM + amountInWithFee);
    }

    function _getInputTokensForExactCerUsd(
        PoolBalances memory poolBalances,
        address _token,
        uint256 _amountCerUsdOut
    )
        internal
        view
        returns (uint256)
    {
        // getting pool storage link (saves gas compared to memory)
        Pool storage pool = pools[cachedTokenValues[_token].poolId];

        return _getInput(
            _amountCerUsdOut,
            uint256(poolBalances.balanceToken),
            uint256(poolBalances.balanceCerUsd),
            _getCurrentFeeBasedOnTrades(
                pool,
                poolBalances
            )
        );
    }

    function _getInputCerUsdForExactTokens(
        PoolBalances memory poolBalances,
        uint256 _amountTokensOut
    )
        internal
        pure
        returns (uint256)
    {
        return _getInput(
            _amountTokensOut,
            uint256(poolBalances.balanceCerUsd),
            uint256(poolBalances.balanceToken),
            0 // fee is zero for swaps cerUsd --> Any
        );
    }

    function _getInput(
        uint256 _amountOut,
        uint256 _reservesIn,
        uint256 _reservesOut,
        uint256 _fee
    )
        internal
        pure
        returns (uint256)
    {
        // refer to https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol
        return _reservesIn
            * _amountOut
            * FEE_DENORM
            / (FEE_DENORM - _fee)
            / (_reservesOut - _amountOut) // or (_reservesOut - _amountOut) is also fine
            + 1; // adding +1 for any rounding trims
    }
}
