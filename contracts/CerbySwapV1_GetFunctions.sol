// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.11;

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
        return tokenToPoolId[_token];
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
        returns (PoolBalances[] memory)
    {
        PoolBalances[] memory outputPools = new PoolBalances[](_tokens.length);
        for (uint256 i; i < _tokens.length; i++) {
            address token = _tokens[i];
            outputPools[i] = _getPoolBalances(token);
        }
        return outputPools;
    }

    function getCurrentOneMinusFeeBasedOnTrades(
        address _token
    )
        external
        view
        returns (uint256 fee)
    {
        // getting pool storage link (saves gas compared to memory)
        Pool storage pool = pools[tokenToPoolId[_token]];
        
        PoolBalances memory poolBalances = _getPoolBalances(
            _token
        );

        return _getCurrentOneMinusFeeBasedOnTrades(
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

        uint256 amountTokensOut;

        // direction XXX --> cerUSD
        if (_tokenOut == cerUsdToken) {
            // getting amountTokensOut
            amountTokensOut = _getOutputExactTokensForCerUsd(
                _getPoolBalances(_tokenIn),
                _tokenIn,
                _amountTokensIn
            );
            return amountTokensOut;
        }

        // direction cerUSD --> YYY
        if (_tokenIn == cerUsdToken) {
            // getting amountTokensOut
            amountTokensOut = _getOutputExactCerUsdForTokens(
                _getPoolBalances(_tokenOut),
                _amountTokensIn
            );
            return amountTokensOut;
        }

        // tokenIn != cerUsdToken && tokenIn != cerUsdToken clause
        // direction XXX --> cerUSD --> YYY (or XXX --> YYY)
        // getting amountTokensOut
        uint256 amountCerUsdOut = _getOutputExactTokensForCerUsd(
            _getPoolBalances(_tokenIn),
            _tokenIn,
            _amountTokensIn
        );

        amountTokensOut = _getOutputExactCerUsdForTokens(
            _getPoolBalances(_tokenOut),
            amountCerUsdOut
        );

        return amountTokensOut;
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

        uint256 amountTokensIn;

        // direction XXX --> cerUSD
        if (_tokenOut == cerUsdToken) {
            // getting amountTokensOut
            amountTokensIn = _getInputTokensForExactCerUsd(
                _getPoolBalances(_tokenIn),
                _tokenIn,
                _amountTokensOut
            );

            return amountTokensIn;
        }

        // direction cerUSD --> YYY
        if (_tokenIn == cerUsdToken) {
            // getting amountTokensOut
            amountTokensIn = _getInputCerUsdForExactTokens(
                _getPoolBalances(_tokenOut),
                _amountTokensOut
            );

            return amountTokensIn;
        }

        // tokenIn != cerUsdToken && tokenIn != cerUsdToken clause
        // direction XXX --> cerUSD --> YYY (or XXX --> YYY)
        // getting amountTokensOut
        uint256 amountCerUsdOut = _getInputCerUsdForExactTokens(
            _getPoolBalances(_tokenIn),
            _amountTokensOut
        );

        amountTokensIn = _getInputTokensForExactCerUsd(
            _getPoolBalances(_tokenOut),
            _tokenIn,
            amountCerUsdOut
        );

        return amountTokensIn;
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

    function _getCurrentOneMinusFeeBasedOnTrades(
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
            return FEE_DENORM - uint256(settings.feeMaximum); // fee is maximum
        }

        if (volume >= tvlMax) {
            return FEE_DENORM - uint256(settings.feeMinimum); // fee is minimum
        }

        return FEE_DENORM - uint256(settings.feeMaximum)
            + ((volume - tvlMin) * (uint256(settings.feeMaximum) - uint256(settings.feeMinimum)))
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
        Pool storage pool = pools[tokenToPoolId[_token]];

        return _getOutput(
            _amountTokensIn,
            uint256(poolBalances.balanceToken),
            uint256(poolBalances.balanceCerUsd),
            _getCurrentOneMinusFeeBasedOnTrades(
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
            FEE_DENORM // fee is zero for swaps cerUsd --> Any (oneMinusFee = FEE_DENORM)
        );
    }

    function _getOutput(
        uint256 _amountIn,
        uint256 _reservesIn,
        uint256 _reservesOut,
        uint256 _oneMinusFee
    )
        internal
        pure
        returns (uint256)
    {
        // refer to https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol
        uint256 amountInWithFee = _amountIn
            * _oneMinusFee;

        uint256 amountOut = _reservesOut
            * amountInWithFee
            / (_reservesIn * FEE_DENORM + amountInWithFee);

        return amountOut;
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
        Pool storage pool = pools[tokenToPoolId[_token]];

        return _getInput(
            _amountCerUsdOut,
            uint256(poolBalances.balanceToken),
            uint256(poolBalances.balanceCerUsd),
            _getCurrentOneMinusFeeBasedOnTrades(
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
            FEE_DENORM // fee is zero for swaps cerUsd --> Any (oneMinusFee = FEE_DENORM)
        );
    }

    function _getInput(
        uint256 _amountOut,
        uint256 _reservesIn,
        uint256 _reservesOut,
        uint256 _oneMinusFee
    )
        internal
        pure
        returns (uint256)
    {
        // refer to https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol
        uint256 amountIn = _reservesIn
            * _amountOut
            * FEE_DENORM
            / _oneMinusFee
            / (_reservesOut - _amountOut) // or (_reservesOut - _amountOut) is also fine
            + 1; // adding +1 for any rounding trims
        return amountIn;
    }
}
