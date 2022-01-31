// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.11;

import "./CerbySwapV1_Modifiers.sol";

abstract contract CerbySwapV1_GetFunctions is CerbySwapV1_Modifiers {

    function getTokenToPoolId(
        address _token
    )
        public
        view returns (uint256)
    {
        return tokenToPoolId[_token];
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
        returns (uint256)
    {
        return (block.timestamp / ONE_PERIOD_IN_SECONDS) % NUMBER_OF_TRADE_PERIODS;
    }

    function getCurrentOneMinusFeeBasedOnTrades(address _token)
        public
        view
        returns (uint256 fee)
    {
        // getting pool storage link (saves gas compared to memory)
        Pool storage pool = pools[tokenToPoolId[_token]];
        return _getCurrentOneMinusFeeBasedOnTrades(pool);
    }

    function _getCurrentOneMinusFeeBasedOnTrades(Pool storage _pool)
        internal
        view
        returns (uint256)
    {
        // getting last 24 hours trade volume in USD
        uint256 currentPeriod = _getCurrentPeriod();
        uint256 nextPeriod = (currentPeriod + 1) % NUMBER_OF_TRADE_PERIODS;
        uint256 volume;

        for (uint256 i; i < NUMBER_OF_TRADE_PERIODS; i++) {
            if (i == currentPeriod || i == nextPeriod) continue;
            volume += _pool.tradeVolumePerPeriodInCerUsd[i];
        }

        uint256 tvlMin = _pool.balanceCerUsd
            * settings.tvlMultiplierMinimum
            / TVL_MULTIPLIER_DENORM;

        uint256 tvlMax = _pool.balanceCerUsd
            * settings.tvlMultiplierMaximum
            / TVL_MULTIPLIER_DENORM;

        volume = volume * TRADE_VOLUME_DENORM;

        if (volume <= tvlMin) {
            return FEE_DENORM - settings.feeMaximum;
        }

        if (volume > tvlMin && volume < tvlMax) {
            return FEE_DENORM
                - (settings.feeMaximum - ((volume - tvlMin)
                * (settings.feeMaximum - settings.feeMinimum))
                / (tvlMax - tvlMin)
            );
        }

        return FEE_DENORM - settings.feeMinimum;
    }

    function getOutputExactTokensForTokens(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountTokensIn
    )
        public // Q: external
        view
        returns (uint256)
    {
        uint256 amountTokensOut;

        // direction XXX --> cerUSD
        if (_tokenIn != cerUsdToken && _tokenOut == cerUsdToken) {
            // getting amountTokensOut
            amountTokensOut = _getOutputExactTokensForCerUsd(
                _tokenIn,
                _amountTokensIn
            );
            return amountTokensOut;
        }

        // direction cerUSD --> YYY
        if (_tokenIn == cerUsdToken && _tokenOut != cerUsdToken) {
            // getting amountTokensOut
            amountTokensOut = _getOutputExactCerUsdForTokens(
                _tokenOut,
                _amountTokensIn
            );
            return amountTokensOut;
        }

        // tokenIn != cerUsdToken && tokenIn != cerUsdToken clause
        // direction XXX --> cerUSD --> YYY (or XXX --> YYY)
        // getting amountTokensOut

        uint256 amountCerUsdOut = _getOutputExactTokensForCerUsd(
            _tokenIn,
            _amountTokensIn
        );

        amountTokensOut = _getOutputExactCerUsdForTokens(
            _tokenOut,
            amountCerUsdOut
        );

        return amountTokensOut;
    }

    function getInputTokensForExactTokens(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountTokensOut
    )
        public
        view
        returns (uint256)
    {
        uint256 amountTokensIn;

        // direction XXX --> cerUSD
        if (_tokenIn != cerUsdToken && _tokenOut == cerUsdToken) {
            // getting amountTokensOut
            amountTokensIn = _getInputTokensForExactCerUsd(
                _tokenIn,
                _amountTokensOut
            );

            return amountTokensIn;
        }

        // direction cerUSD --> YYY
        if (_tokenIn == cerUsdToken && _tokenOut != cerUsdToken) {
            // getting amountTokensOut
            amountTokensIn = _getInputCerUsdForExactTokens(
                _tokenOut,
                _amountTokensOut
            );

            return amountTokensIn;
        }

        // tokenIn != cerUsdToken && tokenIn != cerUsdToken clause
        // direction XXX --> cerUSD --> YYY (or XXX --> YYY)
        // getting amountTokensOut
        uint256 amountCerUsdOut = _getInputCerUsdForExactTokens(
            _tokenOut,
            _amountTokensOut
        );

        amountTokensIn = _getInputTokensForExactCerUsd(
            _tokenIn,
            amountCerUsdOut
        );

        return amountTokensIn;
    }

    function _getOutputExactTokensForCerUsd(
        address _token,
        uint256 _amountTokensIn
    )
        internal
        view
        tokenMustExistInPool(_token)
        returns (uint256)
    {
        // getting pool storage link (saves gas compared to memory)
        Pool storage pool = pools[tokenToPoolId[_token]];

        return _getOutput(
            _amountTokensIn,
            uint256(pool.balanceToken),
            uint256(pool.balanceCerUsd),
            _getCurrentOneMinusFeeBasedOnTrades(pool)
        );
    }

    function _getOutputExactCerUsdForTokens(
        address _token,
        uint256 _amountCerUsdIn
    )
        internal
        view
        tokenMustExistInPool(_token)
        returns (uint256)
    {
        // getting pool storage link (saves gas compared to memory)
        Pool storage pool = pools[tokenToPoolId[_token]];

        return _getOutput(
            _amountCerUsdIn,
            uint256(pool.balanceCerUsd),
            uint256(pool.balanceToken),
            //_getCurrentOneMinusFeeBasedOnTrades(pool)
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
        address _token,
        uint256 _amountCerUsdOut
    )
        internal
        view
        tokenMustExistInPool(_token)
        returns (uint256)
    {
        // getting pool storage link (saves gas compared to memory)
        Pool storage pool = pools[tokenToPoolId[_token]];

        return _getInput(
            _amountCerUsdOut,
            uint256(pool.balanceToken),
            uint256(pool.balanceCerUsd),
            _getCurrentOneMinusFeeBasedOnTrades(pool)
        );
    }

    function _getInputCerUsdForExactTokens(
        address _token,
        uint256 _amountTokensOut
    )
        internal
        view
        tokenMustExistInPool(_token)
        returns (uint256)
    {
        // getting pool storage link (saves gas compared to memory)
        Pool storage pool = pools[tokenToPoolId[_token]];

        return _getInput(
            _amountTokensOut,
            uint256(pool.balanceCerUsd),
            uint256(pool.balanceToken),
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
            / (_oneMinusFee * (_reservesOut - _amountOut))
            + 1; // adding +1 for any rounding trims

        return amountIn;
    }

    function getPoolsByIds(
        uint256[] calldata _ids
    )
        public // Q: external?
        view
        returns (Pool[] memory)
    {
        Pool[] memory outputPools = new Pool[](_ids.length);
        for (uint256 i; i < _ids.length; i++) {
            outputPools[i] = pools[_ids[i]];
        }

        return outputPools;
    }

    function getPoolsByTokens(
        address[] calldata _tokens
    )
        public // Q: external?
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
