// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.11;

import "./CerbySwapV1_Modifiers.sol";
import "./CerbySwapV1_SafeFunctions.sol";

abstract contract CerbySwapV1_GetFunctions is
    CerbySwapV1_Modifiers,
    CerbySwapV1_SafeFunctions
{
    function getTokenToPoolId(address _token) public view returns (uint256) {
        return tokenToPoolId[_token];
    }

    function getSettings() public view returns (Settings memory) {
        return settings;
    }

    function _getCurrentPeriod() internal view returns (uint256) {
        return
            (block.timestamp / ONE_PERIOD_IN_SECONDS) % NUMBER_OF_TRADE_PERIODS;
    }

    function getCurrentOneMinusFeeBasedOnTrades(address _token)
        public
        view
        returns (uint256 fee)
    {
        // getting pool storage link (saves gas compared to memory)
        Pool storage pool = pools[tokenToPoolId[_token]];

        PoolBalances memory poolBalances = _getPoolBalances(
            _token,
            pool.vaultAddress
        );

        return _getCurrentOneMinusFeeBasedOnTrades(pool, poolBalances);
    }

    function _getCurrentOneMinusFeeBasedOnTrades(
        Pool storage _pool,
        PoolBalances memory _poolBalances
    ) internal view returns (uint256) {
        // getting last 24 hours trade volume in USD
        uint256 currentPeriod = _getCurrentPeriod();
        uint256 nextPeriod = (currentPeriod + 1) % NUMBER_OF_TRADE_PERIODS;
        uint256 volume;
        for (uint256 i; i < NUMBER_OF_TRADE_PERIODS; i++) {
            // skipping current and next period because those values are currently updating
            // and are incorrect
            if (i == currentPeriod || i == nextPeriod) continue;

            volume += _pool.tradeVolumePerPeriodInCerUsd[i];
        }

        // multiplying it to make wei dimention
        volume = volume * TRADE_VOLUME_DENORM;

        // trades <= TVL * min              ---> fee = feeMaximum
        // TVL * min < trades < TVL * max   ---> fee is between feeMaximum and feeMinimum
        // trades >= TVL * max              ---> fee = feeMinimum
        uint256 tvlMin = (_poolBalances.balanceCerUsd *
            settings.tvlMultiplierMinimum) / TVL_MULTIPLIER_DENORM;
        uint256 tvlMax = (_poolBalances.balanceCerUsd *
            settings.tvlMultiplierMaximum) / TVL_MULTIPLIER_DENORM;
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
        address _tokenIn,
        address _tokenOut,
        uint256 _amountTokensIn
    ) public view returns (uint256) {
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
    ) public view returns (uint256) {
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
            _getPoolBalances(_tokenIn, vaultAddressIn),
            _tokenOut,
            _amountTokensOut
        );

        amountTokensIn = _getInputTokensForExactCerUsd(
            _getPoolBalances(_tokenOut, vaultAddressOut),
            _tokenIn,
            amountCerUsdOut
        );
        return amountTokensIn;
    }

    function _getOutputExactTokensForCerUsd(
        PoolBalances memory poolBalances,
        address _token,
        uint256 _amountTokensIn
    ) internal view tokenMustExistInPool(_token) returns (uint256) {
        // getting pool storage link (saves gas compared to memory)
        Pool storage pool = pools[tokenToPoolId[_token]];

        return
            _getOutput(
                _amountTokensIn,
                uint256(poolBalances.balanceToken),
                uint256(poolBalances.balanceCerUsd),
                _getCurrentOneMinusFeeBasedOnTrades(pool, poolBalances)
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
        Pool storage pool = pools[tokenToPoolId[_token]];

        return
            _getInput(
                _amountCerUsdOut,
                uint256(poolBalances.balanceToken),
                uint256(poolBalances.balanceCerUsd),
                _getCurrentOneMinusFeeBasedOnTrades(pool, poolBalances)
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

    function getPoolsByIds(uint256[] calldata _ids)
        public
        view
        returns (Pool[] memory)
    {
        Pool[] memory outputPools = new Pool[](_ids.length);
        for (uint256 i; i < _ids.length; i++) {
            outputPools[i] = pools[_ids[i]];
        }
        return outputPools;
    }

    function getPoolsByTokens(address[] calldata _tokens)
        public
        view
        returns (Pool[] memory)
    {
        Pool[] memory outputPools = new Pool[](_tokens.length);
        for (uint256 i; i < _tokens.length; i++) {
            outputPools[i] = pools[tokenToPoolId[_tokens[i]]];
        }
        return outputPools;
    }
}
