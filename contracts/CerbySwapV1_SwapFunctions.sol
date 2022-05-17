// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.13;

import "./CerbySwapV1_LiquidityFunctions.sol";

abstract contract CerbySwapV1_SwapFunctions is CerbySwapV1_LiquidityFunctions {

    function swapExactTokensForTokens(
        ICerbyERC20 _tokenIn,
        ICerbyERC20 _tokenOut,
        uint256 _amountTokensIn,
        uint256 _minAmountTokensOut,
        uint256 _expireTimestamp,
        address _transferTo
    )
        external
        payable
        transactionIsNotExpired(_expireTimestamp)
        // checkForBots(msg.sender) // TODO: enable on production
        returns (uint256[] memory)
    {
        return _swapExactTokensForTokens(
            _tokenIn,
            _tokenOut,
            _amountTokensIn,
            _minAmountTokensOut,
            _transferTo
        );
    }

    function swapTokensForExactTokens(
        ICerbyERC20 _tokenIn,
        ICerbyERC20 _tokenOut,
        uint256 _amountTokensOut,
        uint256 _maxAmountTokensIn,
        uint256 _expireTimestamp,
        address _transferTo
    )
        external
        payable
        transactionIsNotExpired(_expireTimestamp)
        // checkForBots(msg.sender) // TODO: enable on production
        returns (uint256[] memory)
    {
        return _swapTokensForExactTokens(
            _tokenIn,
            _tokenOut,
            _amountTokensOut,
            _maxAmountTokensIn,
            _transferTo
        );
    }

    function _swapExactTokensForTokens(
        ICerbyERC20 _tokenIn,
        ICerbyERC20 _tokenOut,
        uint256 _amountTokensIn,
        uint256 _minAmountTokensOut,
        address _transferTo
    )
        private
        returns (uint256[] memory)
    {
        // does not make sense to do the swap XXX --> XXX
        if (_tokenIn == _tokenOut) {
            revert("L"); // TODO: remove this line on production
            revert CerbySwapV1_SwappingTokenToSameTokenIsForbidden();
        }

        ICerbySwapV1_Vault vaultAddressIn = _getCachedVaultCloneAddressByToken(
            _tokenIn
        );

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = _amountTokensIn;

        PoolBalances memory poolInBalancesBefore;

        // swaping XXX --> CERBY
        if (_tokenOut == CERBY_TOKEN) {
            // getting pool balances before the swap
            poolInBalancesBefore = _getPoolBalances(
                _tokenIn
            );

            // getting amountTokensOut
            amounts[1] = _getOutputExactTokensForCerby(
                poolInBalancesBefore,
                _tokenIn,
                _amountTokensIn
            );

            // checking slippage
            if (amounts[1] < _minAmountTokensOut) {
                revert("H"); // TODO: remove this line on production
                revert CerbySwapV1_OutputCerbyAmountIsLowerThanMinimumSpecified();
            }

            // safely transferring tokens from sender to the vault
            _safeTransferFromHelper(
                _tokenIn,
                msg.sender,
                address(vaultAddressIn),
                _amountTokensIn
            );

            // swapping XXX ---> CERBY
            _swap(
                _tokenIn,
                poolInBalancesBefore,
                _amountTokensIn,
                0,
                0,
                amounts[1],
                _transferTo
            );

            return amounts;
        }

        // swaping CERBY --> YYY
        ICerbySwapV1_Vault vaultAddressOut = _getCachedVaultCloneAddressByToken(
            _tokenOut
        );

        PoolBalances memory poolOutBalancesBefore;

        if (_tokenIn == CERBY_TOKEN) {
            // getting pool balances before the swap
            poolOutBalancesBefore = _getPoolBalances(
                _tokenOut
            );

            // getting amountTokensOut
            amounts[1] = _getOutputExactCerbyForTokens(
                poolOutBalancesBefore,
                _amountTokensIn
            );

            // checking slippage
            if (amounts[1] < _minAmountTokensOut) {
                revert("i"); // TODO: remove this line on production
                revert CerbySwapV1_OutputTokensAmountIsLowerThanMinimumSpecified();
            }

            // safely transferring tokens from sender to the vault
            _safeTransferFromHelper(
                _tokenIn,
                msg.sender,
                address(vaultAddressOut),
                _amountTokensIn
            );

            // swapping CERBY ---> YYY
            _swap(
                _tokenOut,
                poolOutBalancesBefore,
                0,
                _amountTokensIn,
                amounts[1],
                0,
                _transferTo
            );

            return amounts;
        }

        // if (tokenIn != tokenOut && tokenIn != CERBY_TOKEN && tokenOut != CERBY_TOKEN)
        // swaping XXX --> CERBY --> YYY (or XXX --> YYY)

        // getting pool balances before the swap
        poolInBalancesBefore = _getPoolBalances(
            _tokenIn
        );

        // getting amountTokensOut=
        uint256 amountCerbyOut = _getOutputExactTokensForCerby(
            poolInBalancesBefore,
            _tokenIn,
            _amountTokensIn
        );

        // getting pool balances before the swap
        poolOutBalancesBefore = _getPoolBalances(
            _tokenOut
        );

        amounts[1] = _getOutputExactCerbyForTokens(
            poolOutBalancesBefore,
            amountCerbyOut
        );

        // checking slippage
        if (amounts[1] < _minAmountTokensOut) {
            revert("i"); // TODO: remove this line on production
            revert CerbySwapV1_OutputTokensAmountIsLowerThanMinimumSpecified();
        }

        // safely transferring tokens from sender to the vault
        _safeTransferFromHelper(
            _tokenIn,
            msg.sender,
            address(vaultAddressIn),
            _amountTokensIn
        );

        // swapping XXX ---> CERBY
        // keeping all output CERBY in the contract without sending
        _swap(
            _tokenIn,
            poolInBalancesBefore,
            _amountTokensIn, 
            0,
            0,
            amountCerbyOut,
            address(vaultAddressOut)
        );

        // swapping CERBY ---> YYY
        _swap(
            _tokenOut,
            poolOutBalancesBefore,
            0,
            amountCerbyOut,
            amounts[1],
            0,
            _transferTo
        );

        return amounts;
    }

    function _swapTokensForExactTokens(
        ICerbyERC20 _tokenIn,
        ICerbyERC20 _tokenOut,
        uint256 _amountTokensOut,
        uint256 _maxAmountTokensIn,
        address _transferTo
    )
        private
        returns (uint256[] memory)
    {
        if (_tokenIn == _tokenOut) {
            revert("L"); // TODO: remove this line on production
            revert CerbySwapV1_SwappingTokenToSameTokenIsForbidden();
        }

        ICerbySwapV1_Vault vaultAddressIn = _getCachedVaultCloneAddressByToken(
            _tokenIn
        );

        uint256[] memory amounts = new uint256[](2);
        amounts[1] = _amountTokensOut;

        PoolBalances memory poolInBalancesBefore;

        // swapping XXX --> CERBY
        if (_tokenOut == CERBY_TOKEN) {
            // getting pool balances before the swap
            poolInBalancesBefore = _getPoolBalances(
                _tokenIn
            );

            // getting amountTokensOut
            amounts[0] = _getInputTokensForExactCerby(
                poolInBalancesBefore,
                _tokenIn,
                _amountTokensOut
            );

            // checking slippage
            if (amounts[0] > _maxAmountTokensIn) {
                revert("K"); // TODO: remove this line on production
                revert CerbySwapV1_InputTokensAmountIsLargerThanMaximumSpecified();
            }

            // safely transferring tokens from sender to the vault
            _safeTransferFromHelper(
                _tokenIn,
                msg.sender,
                address(vaultAddressIn),
                amounts[0]
            );

            // swapping XXX ---> CERBY
            _swap(
                _tokenIn,
                poolInBalancesBefore,
                amounts[0],
                0,
                0,
                _amountTokensOut,
                _transferTo
            );

            return amounts;
        }

        // swapping CERBY --> YYY
        ICerbySwapV1_Vault vaultAddressOut = _getCachedVaultCloneAddressByToken(
            _tokenOut
        );

        PoolBalances memory poolOutBalancesBefore;

        if (_tokenIn == CERBY_TOKEN) {
            // getting pool balances before the swap
            poolOutBalancesBefore = _getPoolBalances(
                _tokenOut
            );

            // getting amountTokensOut
            amounts[0] = _getInputCerbyForExactTokens(
                poolOutBalancesBefore,
                _amountTokensOut
            );

            // checking slippage
            if (amounts[0] > _maxAmountTokensIn) {
                revert("J"); // TODO: remove this line on production
                revert CerbySwapV1_InputCerbyAmountIsLargerThanMaximumSpecified();
            }

            // safely transferring tokens from sender to the vault
            _safeTransferFromHelper(
                _tokenIn,
                msg.sender,
                address(vaultAddressOut),
                amounts[0]
            );

            // swapping CERBY ---> YYY
            _swap(
                _tokenOut,
                poolOutBalancesBefore,
                0,
                amounts[0],
                _amountTokensOut,
                0,
                _transferTo
            );

            return amounts;
        }

        // if (_tokenIn != CERBY_TOKEN && _tokenOut != CERBY_TOKEN && _tokenIn != _tokenOut)
        // swaping XXX --> CERBY --> YYY (or XXX --> YYY)

        // getting pool balances before the swap
        poolOutBalancesBefore = _getPoolBalances(
            _tokenOut
        );

        // getting amountTokensOut
        uint256 amountCerbyOut = _getInputCerbyForExactTokens(
            poolOutBalancesBefore,
            _amountTokensOut
        );

        // amountCerbyOut must be larger than 1 to avoid rounding errors
        if (amountCerbyOut <= 1) {
            revert("U"); // TODO: remove this line on production
            revert CerbySwapV1_AmountOfCerbyMustBeLargerThanOne();
        }

        // getting pool balances before the swap
        poolInBalancesBefore = _getPoolBalances(
            _tokenIn
        );

        // amounts[0] is amountTokensIn
        amounts[0] = _getInputTokensForExactCerby(
            poolInBalancesBefore,
            _tokenIn,
            amountCerbyOut
        );

        // checking slippage
        if (amounts[0] > _maxAmountTokensIn) {
            revert("K"); // TODO: remove this line on production
            revert CerbySwapV1_InputTokensAmountIsLargerThanMaximumSpecified();
        }

        // safely transferring tokens from sender to the vault
        _safeTransferFromHelper(
            _tokenIn,
            msg.sender,
            address(vaultAddressIn),
            amounts[0]
        );

        // swapping XXX ---> CERBY
        _swap(
            _tokenIn,
            poolInBalancesBefore,
            amounts[0],
            0,
            0,
            amountCerbyOut,
            address(vaultAddressOut)
        );

        // swapping CERBY ---> YYY
        _swap(
            _tokenOut,
            poolOutBalancesBefore,
            0,
            amountCerbyOut,
            _amountTokensOut,
            0,
            _transferTo
        );

        return amounts;
    }

    function _swap(
        ICerbyERC20 _token,
        PoolBalances memory _poolBalancesBefore,
        uint256 _amountTokensIn,
        uint256 _amountCerbyIn,
        uint256 _amountTokensOut,
        uint256 _amountCerbyOut,
        address _transferTo
    )
        private
    {
        // at least one of amountTokensIn or amountCerbyIn must be larger than 1
        if (_amountTokensIn + _amountCerbyIn <= 1) {
            revert("2");
            revert CerbySwapV1_AmountOfCerbyOrTokensInMustBeLargerThanOne();
        }

        Pool storage pool = pools[cachedTokenValues[_token].poolId];

        // checking if CERBY credit is enough to cover this swap
        if (
            pool.creditCerby != MAX_CERBY_CREDIT && // skipping official pools where pool.creditCerby == MAX_CERBY_CREDIT
            uint256(pool.creditCerby) + _amountCerbyIn < _amountCerbyOut // making sure that updated credit will not underflow
        ) {
            revert("Z");
            revert CerbySwapV1_CreditCerbyMustNotBeBelowZero();
        }

        uint256 currentPeriod = _getCurrentPeriod();
        uint256 fee;
        PoolBalances memory poolBalancesAfter = PoolBalances({
            balanceToken: _poolBalancesBefore.balanceToken + _amountTokensIn - _amountTokensOut,
            balanceCerby: _poolBalancesBefore.balanceCerby + _amountCerbyIn - _amountCerbyOut
        });

        {
            // calculating fees
            // if swap is XXX --> CERBY, fee is calculated
            // else swap is CERBY --> XXX, fee is zero
            if (_amountCerbyIn <= 1 && _amountTokensIn > 1) {

                // caching it for whole current period
                uint256 lastPeriodI = uint256(
                    pool.lastCachedTradePeriod
                );

                if (lastPeriodI != currentPeriod) {

                    uint256 endPeriod = currentPeriod < lastPeriodI ? 
                        currentPeriod + NUMBER_OF_TRADE_PERIODS :
                            currentPeriod;
                    
                    // setting trade volume periods to 1
                    // iterating from (lastCachedTradePeriod+1) to currentPeriod (inclusive)
                    while(++lastPeriodI <= endPeriod) {
                        pool.tradeVolumePerPeriodInCerby[lastPeriodI % NUMBER_OF_TRADE_PERIODS] = 1;
                    }

                    // caching fee
                    pool.lastCachedFee = uint8(
                        _getCurrentFeeBasedOnTrades(
                            pool,
                            _poolBalancesBefore
                        )
                    );

                    pool.lastCachedTradePeriod = uint8(
                        currentPeriod
                    );
                }

                fee = uint256(pool.lastCachedFee);
            }

            // calculating old K value including trade fees (multiplied by FEE_DENORM^2)
            uint256 beforeKValueDenormed = _poolBalancesBefore.balanceToken * 
                _poolBalancesBefore.balanceCerby * FEE_DENORM_SQUARED;

            // calculating new K value including trade fees
            // refer to 3.2.1 Adjustment for fee https://uniswap.org/whitepaper.pdf
            uint256 afterKValueDenormed = (
                    poolBalancesAfter.balanceCerby * FEE_DENORM - // FEE_DENORM = 1000 in uniswap wp                    
                        _amountCerbyIn * fee // fee = 3 in uniswap wp
                ) *
                (
                    poolBalancesAfter.balanceToken * FEE_DENORM - // FEE_DENORM = 1000 in uniswap wp
                        _amountTokensIn * fee // fee = 3 in uniswap wp
                );

            if (afterKValueDenormed < beforeKValueDenormed) {
                revert("1"); // TODO: remove on production
                revert CerbySwapV1_InvariantKValueMustBeSameOrIncreasedOnAnySwaps();
            }

            // updating creditCerby only if pool is user-created
            if (pool.creditCerby < MAX_CERBY_CREDIT) {
                pool.creditCerby = uint128(
                    uint256(pool.creditCerby) + _amountCerbyIn -
                        _amountCerbyOut
                );
            }

            // updating 1 hour trade pool values
            // only for direction ANY --> CERBY
            if (_amountCerbyOut > TRADE_VOLUME_DENORM) {
                // or else amountCerbyOut / TRADE_VOLUME_DENORM == 0
                // stores in 10xUSD value, up-to $40B per 4 hours per pair will be stored correctly
                uint256 updatedTradeVolume = _amountCerbyOut / TRADE_VOLUME_DENORM +
                    uint256(pool.tradeVolumePerPeriodInCerby[currentPeriod]); // if ANY --> CERBY, then output is CERBY only

                // handling overflow just in case
                pool.tradeVolumePerPeriodInCerby[currentPeriod] = 
                    updatedTradeVolume < type(uint40).max ? uint40(updatedTradeVolume) :
                        type(uint40).max;
            }
        }

        // updating vault cache if needed
        ICerbySwapV1_Vault vaultAddress = _getCachedVaultCloneAddressByToken(
            _token
        );

        // safely transfering CERBY
        _safeTransferFromHelper(
            CERBY_TOKEN,
            address(vaultAddress),
            _transferTo,
            _amountCerbyOut
        );

        // safely transfering tokens
        _safeTransferFromHelper(
            _token,
            address(vaultAddress),
            _transferTo,
            _amountTokensOut
        );

        // Swap event is needed to post in telegram channel
        emit Swap(
            _token,
            msg.sender,
            _amountTokensIn,
            _amountCerbyIn,
            _amountTokensOut,
            _amountCerbyOut,
            fee,
            _transferTo
        );

        // Sync event to update pool variables in the graph node
        emit Sync(
            _token,
            poolBalancesAfter.balanceToken,
            poolBalancesAfter.balanceCerby,
            pool.creditCerby
        );
    }
}
