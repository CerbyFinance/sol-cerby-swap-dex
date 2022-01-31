// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.11;

import "./CerbySwapV1_Modifiers.sol";
import "./CerbySwapV1_SafeFunctions.sol";

abstract contract CerbySwapV1_GetFunctions is
    CerbySwapV1_Modifiers,
    CerbySwapV1_SafeFunctions
{
    function getTokenToPoolId(address _token) external view returns (uint256) {
        return tokenToPoolId[_token];
    }

    function getSettings() external view returns (Settings memory) {
        return settings;
    }

    function getCurrentOneMinusFeeBasedOnTrades(address _token)
        external
        view
        returns (uint256 fee)
    {
        // getting pool storage link (saves gas compared to memory)
        Pool storage pool = pools[tokenToPoolId[_token]];

        PoolBalances memory poolBalances = _getPoolBalances(
            _token,
            pool.vaultAddress
        );

        return _getCurrentOneMinusFeeBasedOnTrades(_token, poolBalances);
    }

    function getPoolsByTokens(address[] calldata _tokens)
        external
        view
        returns (PoolBalances[] memory)
    {
        PoolBalances[] memory outputPools = new PoolBalances[](_tokens.length);
        for (uint256 i; i < _tokens.length; i++) {
            address token = _tokens[i];
            Pool storage pool = pools[tokenToPoolId[token]];
            outputPools[i] = _getPoolBalances(token, pool.vaultAddress);
        }
        return outputPools;
    }

    function getOutputExactTokensForTokens(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountTokensIn
    ) external view returns (uint256) {
        uint256 amountTokensOut;

        address vaultAddressIn = pools[tokenToPoolId[_tokenIn]].vaultAddress;
        address vaultAddressOut = pools[tokenToPoolId[_tokenOut]].vaultAddress;

        // direction XXX --> cerUSD
        if (_tokenIn != cerUsdToken && _tokenOut == cerUsdToken) {
            // getting amountTokensOut
            amountTokensOut = _getOutputExactTokensForCerUsd(
                _getPoolBalances(_tokenIn, vaultAddressIn),
                _tokenIn,
                _amountTokensIn
            );
            return amountTokensOut;
        }

        // direction cerUSD --> YYY
        if (_tokenIn == cerUsdToken && _tokenOut != cerUsdToken) {
            // getting amountTokensOut
            amountTokensOut = _getOutputExactCerUsdForTokens(
                _getPoolBalances(_tokenOut, vaultAddressOut),
                _tokenOut,
                _amountTokensIn
            );
            return amountTokensOut;
        }

        // tokenIn != cerUsdToken && tokenIn != cerUsdToken clause
        // direction XXX --> cerUSD --> YYY (or XXX --> YYY)
        // getting amountTokensOut
        uint256 amountCerUsdOut = _getOutputExactTokensForCerUsd(
            _getPoolBalances(_tokenIn, vaultAddressIn),
            _tokenIn,
            _amountTokensIn
        );

        amountTokensOut = _getOutputExactCerUsdForTokens(
            _getPoolBalances(_tokenOut, vaultAddressOut),
            _tokenOut,
            amountCerUsdOut
        );
        return amountTokensOut;
    }

    function getInputTokensForExactTokens(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountTokensOut
    ) external view returns (uint256) {
        uint256 amountTokensIn;

        address vaultAddressIn = pools[tokenToPoolId[_tokenIn]].vaultAddress;
        address vaultAddressOut = pools[tokenToPoolId[_tokenOut]].vaultAddress;

        // direction XXX --> cerUSD
        if (_tokenIn != cerUsdToken && _tokenOut == cerUsdToken) {
            // getting amountTokensOut
            amountTokensIn = _getInputTokensForExactCerUsd(
                _getPoolBalances(_tokenIn, vaultAddressIn),
                _tokenIn,
                _amountTokensOut
            );
            return amountTokensIn;
        }

        // direction cerUSD --> YYY
        if (_tokenIn == cerUsdToken && _tokenOut != cerUsdToken) {
            // getting amountTokensOut
            amountTokensIn = _getInputCerUsdForExactTokens(
                _getPoolBalances(_tokenOut, vaultAddressOut),
                _tokenOut,
                _amountTokensOut
            );
            return amountTokensIn;
        }

        // tokenIn != cerUsdToken && tokenIn != cerUsdToken clause
        // direction XXX --> cerUSD --> YYY (or XXX --> YYY)
        // getting amountTokensOut
        uint256 amountCerUsdOut = _getInputCerUsdForExactTokens(
            _getPoolBalances(_tokenOut, vaultAddressOut),
            _tokenOut,
            _amountTokensOut
        );

        amountTokensIn = _getInputTokensForExactCerUsd(
            _getPoolBalances(_tokenIn, vaultAddressIn),
            _tokenIn,
            amountCerUsdOut
        );
        return amountTokensIn;
    }

    function _getCurrentPeriod() internal view returns (uint256) {
        return block.timestamp / ONE_PERIOD_IN_SECONDS;
    }

    function _getCurrentOneMinusFeeBasedOnTrades(
        address _token,
        PoolBalances memory _poolBalances
    ) internal view returns (uint256) {
        // getting last 24 hours trade volume in USD
        uint256 currentPeriod = _getCurrentPeriod();
        uint256 volume;
        for (
            uint256 i = currentPeriod -
                settings.sincePeriodAgoToTrackTradeVolume;
            i < currentPeriod;
            i++
        ) {
            // skipping current period because this values is currently updating

            volume += hourlyTradeVolumeInCerUsd[_token][i];
        }

        // trades <= TVL * min              ---> fee = feeMaximum
        // TVL * min < trades < TVL * max   ---> fee is between feeMaximum and feeMinimum
        // trades >= TVL * max              ---> fee = feeMinimum
        uint256 tvlMin = (_poolBalances.balanceCerUsd *
            settings.tvlMultiplierMinimum) / TVL_MULTIPLIER_DENORM;
        uint256 tvlMax = (_poolBalances.balanceCerUsd *
            settings.tvlMultiplierMaximum) / TVL_MULTIPLIER_DENORM;
        if (volume <= tvlMin) {
            return FEE_DENORM - settings.feeMaximum; // fee is maximum
        } else if (volume >= tvlMax) {
            return FEE_DENORM - settings.feeMinimum; // fee is minimum
        }

        // if (tvlMin < volume && volume < tvlMax) {
        return
            FEE_DENORM -
            settings.feeMaximum +
            ((volume - tvlMin) * (settings.feeMaximum - settings.feeMinimum)) /
            (tvlMax - tvlMin); // between minimum and maximum
    }

    function _getOutputExactTokensForCerUsd(
        PoolBalances memory poolBalances,
        address _token,
        uint256 _amountTokensIn
    ) internal view tokenMustExistInPool(_token) returns (uint256) {
        return
            _getOutput(
                _amountTokensIn,
                uint256(poolBalances.balanceToken),
                uint256(poolBalances.balanceCerUsd),
                _getCurrentOneMinusFeeBasedOnTrades(_token, poolBalances)
            );
    }

    function _getOutputExactCerUsdForTokens(
        PoolBalances memory poolBalances,
        address _token,
        uint256 _amountCerUsdIn
    ) internal view tokenMustExistInPool(_token) returns (uint256) {
        return
            _getOutput(
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
    ) internal pure returns (uint256) {
        // refer to https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol
        uint256 amountInWithFee = _amountIn * _oneMinusFee;
        uint256 amountOut = (_reservesOut * amountInWithFee) /
            (_reservesIn * FEE_DENORM + amountInWithFee);
        return amountOut;
    }

    function _getInputTokensForExactCerUsd(
        PoolBalances memory poolBalances,
        address _token,
        uint256 _amountCerUsdOut
    ) internal view tokenMustExistInPool(_token) returns (uint256) {
        // getting pool storage link (saves gas compared to memory)
        return
            _getInput(
                _amountCerUsdOut,
                uint256(poolBalances.balanceToken),
                uint256(poolBalances.balanceCerUsd),
                _getCurrentOneMinusFeeBasedOnTrades(_token, poolBalances)
            );
    }

    function _getInputCerUsdForExactTokens(
        PoolBalances memory poolBalances,
        address _token,
        uint256 _amountTokensOut
    ) internal view tokenMustExistInPool(_token) returns (uint256) {
        return
            _getInput(
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
    ) internal pure returns (uint256) {
        // refer to https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol
        uint256 amountIn = (_reservesIn * _amountOut * FEE_DENORM) /
            (_oneMinusFee * (_reservesOut - _amountOut)) +
            1; // adding +1 for any rounding trims
        return amountIn;
    }
}
