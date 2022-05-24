// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.14;

import "./CerbySwapV1_Modifiers.sol";

abstract contract CerbySwapV1_GetFunctions is
    CerbySwapV1_Modifiers
{
    function token0()
        external
        pure
        returns(ICerbyERC20)
    {
        return CERBY_TOKEN;
    }
    
    function token1()
        external
        pure
        returns(ICerbyERC20)
    {
        return NATIVE_TOKEN;
    }


    function getPoolBalancesByToken(
        ICerbyERC20 _token
    )
        external
        view
        returns (PoolBalances memory)
    {
        return _getPoolBalances(_token);
    }

    function getTokenToPoolId(
        ICerbyERC20 _token
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
        ICerbyERC20[] calldata _tokens
    )
        external
        view
        returns (Pool[] memory)
    {
        Pool[] memory outputPools = new Pool[](_tokens.length);
        uint256 tokensLength = _tokens.length;
        for (uint256 i; i < tokensLength; ) {
            outputPools[i] = pools[cachedTokenValues[_tokens[i]].poolId];

            unchecked { 
                ++i; 
            }
        }
        return outputPools;
    }

    function getPoolsBalancesByTokens(
        ICerbyERC20[] calldata _tokens
    )
        external
        view
        returns (PoolBalances[] memory)
    {
        PoolBalances[] memory outputPools = new PoolBalances[](_tokens.length);
        uint256 tokensLength = _tokens.length;
        for (uint256 i; i < tokensLength; ) {
            outputPools[i] = _getPoolBalances(_tokens[i]);

            unchecked { 
                ++i; 
            }
        }
        return outputPools;
    }

    function getOutputExactTokensForTokens(
        ICerbyERC20 _tokenIn,
        ICerbyERC20 _tokenOut,
        uint256 _amountTokensIn
    )
        external
        view
        returns (uint256)
    {
        // caller responsibility to provide
        // _tokenIn != _tokenOut

        // direction XXX --> CERBY
        if (_tokenOut == CERBY_TOKEN) {
            // getting amountTokensOut
            return _getOutputExactTokensForCerby(
                _getPoolBalances(_tokenIn),
                _amountTokensIn
            );
        }

        // direction CERBY --> YYY
        if (_tokenIn == CERBY_TOKEN) {
            // getting amountTokensOut
            return _getOutputExactCerbyForTokens(
                _getPoolBalances(_tokenOut),
                _tokenOut,
                _amountTokensIn
            );
        }

        // tokenIn != CERBY_TOKEN && tokenOut != CERBY_TOKEN clause
        // direction XXX --> CERBY --> YYY (or XXX --> YYY)
        // getting amountTokensOut
        uint256 amountCerbyOut = _getOutputExactTokensForCerby(
            _getPoolBalances(_tokenIn),
            _amountTokensIn
        );

        return _getOutputExactCerbyForTokens(
            _getPoolBalances(_tokenOut),
            _tokenOut,
            amountCerbyOut
        );
    }

    function getInputTokensForExactTokens(
        ICerbyERC20 _tokenIn,
        ICerbyERC20 _tokenOut,
        uint256 _amountTokensOut
    )
        external
        view
        returns (uint256)
    {
        // caller responsibility to provide
        // _tokenIn != _tokenOut

        // direction XXX --> CERBY
        if (_tokenOut == CERBY_TOKEN) {
            // getting amountTokensOut
            return _getInputTokensForExactCerby(
                _getPoolBalances(_tokenIn),
                _amountTokensOut
            );
        }

        // direction CERBY --> YYY
        if (_tokenIn == CERBY_TOKEN) {
            // getting amountTokensOut
            return _getInputCerbyForExactTokens(
                _getPoolBalances(_tokenOut),
                _tokenOut,
                _amountTokensOut
            );
        }

        // tokenIn != CERBY_TOKEN && tokenIn != CERBY_TOKEN clause
        // direction XXX --> CERBY --> YYY (or XXX --> YYY)
        // getting amountTokensOut
        uint256 amountCerbyOut = _getInputCerbyForExactTokens(
            _getPoolBalances(_tokenOut),
            _tokenOut,
            _amountTokensOut
        );

        return _getInputTokensForExactCerby(
            _getPoolBalances(_tokenIn),
            amountCerbyOut
        );
    }

    function _getPoolBalances(
        ICerbyERC20 _token
    )
        internal
        view
        returns (PoolBalances memory)
    {
        if (NATIVE_TOKEN == _token) {
            return PoolBalances(
                address(this).balance,
                _getTokenBalance(CERBY_TOKEN, ICerbySwapV1_Vault(address(this)))
            );
        }

        // non-native token
        ICerbySwapV1_Vault vault = cachedTokenValues[_token].vaultAddress;

        return PoolBalances(
            _getTokenBalance(_token, vault),
            _getTokenBalance(CERBY_TOKEN, vault)
        );
    }

    function _getTokenBalance(
        ICerbyERC20 _token,
        ICerbySwapV1_Vault _vault
    )
        internal
        view
        returns (uint256)
    {
        return _token == NATIVE_TOKEN ? address(_vault).balance :
            _token.balanceOf(address(_vault));
    }

    function _getVaultAddress(ICerbyERC20 _token)
        internal
        view
        returns(ICerbySwapV1_Vault)
    {
        if (NATIVE_TOKEN == _token) return ICerbySwapV1_Vault(address(this));

        // non-native token vault is always cached
        return cachedTokenValues[_token].vaultAddress;
    }

    function _getCurrentFeeBasedOnTrades(
        uint256 _sellVolumeThisPeriodInCerby,
        PoolBalances memory _poolBalances
    )
        internal
        view
        returns (uint256)
    {

        // trades <= TVL * min              ---> fee = feeMaximum
        // TVL * min < trades < TVL * max   ---> fee is between feeMaximum and feeMinimum
        // trades >= TVL * max              ---> fee = feeMinimum
        uint256 tvlMin = _poolBalances.balanceCerby * uint256(settings.tvlMultiplierMinimum) / 
            TVL_MULTIPLIER_DENORM;

        if (_sellVolumeThisPeriodInCerby <= tvlMin) {
            return uint256(settings.feeMaximum); // fee is maximum
        }

        uint256 tvlMax = _poolBalances.balanceCerby * uint256(settings.tvlMultiplierMaximum) /
            TVL_MULTIPLIER_DENORM;
        if (_sellVolumeThisPeriodInCerby >= tvlMax) {
            return uint256(settings.feeMinimum); // fee is minimum
        }

        // fee is between minimum and maximum
        return uint256(settings.feeMaximum) - 
            (uint256(settings.feeMaximum) - uint256(settings.feeMinimum)) * 
            (_sellVolumeThisPeriodInCerby - tvlMin) / (tvlMax - tvlMin); 
    }

    function _getOutputExactTokensForCerby(
        PoolBalances memory poolBalances,
        uint256 _amountTokensIn
    )
        internal
        pure
        returns (uint256)
    {

        return _getOutput(
            _amountTokensIn,
            uint256(poolBalances.balanceToken),
            uint256(poolBalances.balanceCerby),
            0 // fee is zero for swaps XXX --> CERBY
        );
    }

    function _getOutputExactCerbyForTokens(
        PoolBalances memory poolBalances,
        ICerbyERC20 _token,
        uint256 _amountCerbyIn
    )
        internal
        view
        returns (uint256)
    {
        // getting pool storage link (saves gas compared to memory)
        Pool storage pool = pools[cachedTokenValues[_token].poolId];

        return _getOutput(
            _amountCerbyIn,
            uint256(poolBalances.balanceCerby),
            uint256(poolBalances.balanceToken),
            pool.lastCachedFee
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
        // refer to https://github.com/Uniswap/v2-periphery/blob/2efa12e0f2d808d9b49737927f0e416fafa5af68/contracts/libraries/UniswapV2Library.sol#L43-L50
        uint256 amountInWithFee = _amountIn * (FEE_DENORM - _fee);

        return amountInWithFee * _reservesOut / 
            (_reservesIn * FEE_DENORM + amountInWithFee);
    }

    function _getInputTokensForExactCerby(
        PoolBalances memory poolBalances,
        uint256 _amountCerbyOut
    )
        internal
        pure
        returns (uint256)
    {

        return _getInput(
            _amountCerbyOut,
            uint256(poolBalances.balanceToken),
            uint256(poolBalances.balanceCerby),
            0 // fee is zero for swaps XXX --> CERBY
        );
    }

    function _getInputCerbyForExactTokens(
        PoolBalances memory poolBalances,
        ICerbyERC20 _token,
        uint256 _amountTokensOut
    )
        internal
        view
        returns (uint256)
    {
        // getting pool storage link (saves gas compared to memory)
        Pool storage pool = pools[cachedTokenValues[_token].poolId];

        return _getInput(
            _amountTokensOut,
            uint256(poolBalances.balanceCerby),
            uint256(poolBalances.balanceToken),  
            pool.lastCachedFee
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
        // refer to https://github.com/Uniswap/v2-periphery/blob/2efa12e0f2d808d9b49737927f0e416fafa5af68/contracts/libraries/UniswapV2Library.sol#L53-L59
        return _reservesIn * _amountOut * FEE_DENORM /
            ((FEE_DENORM - _fee) * (_reservesOut - _amountOut)) +
            1; // adding +1 for any rounding trims
    }
}
