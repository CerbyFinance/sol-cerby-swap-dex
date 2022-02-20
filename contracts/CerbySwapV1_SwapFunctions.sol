// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.12;

import "./CerbySwapV1_LiquidityFunctions.sol";

abstract contract CerbySwapV1_SwapFunctions is CerbySwapV1_LiquidityFunctions {

    function swapExactTokensForTokens(
        address _tokenIn,
        address _tokenOut,
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
        // does not make sense to do the swap ANY --> ANY
        if (_tokenIn == _tokenOut) {
            revert("L"); // TODO: remove this line on production
            revert CerbySwapV1_SwappingTokenToSameTokenIsForbidden();
        }

        address vaultAddressIn = _getCachedVaultCloneAddressByToken(
            _tokenIn
        );

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = _amountTokensIn;

        PoolBalances memory poolInBalancesBefore;

        // swaping XXX --> cerUSD
        if (_tokenOut == CER_USD_TOKEN) {
            // getting pool balances before the swap
            poolInBalancesBefore = _getPoolBalances(
                _tokenIn
            );

            // getting amountTokensOut
            amounts[1] = _getOutputExactTokensForCerUsd(
                poolInBalancesBefore,
                _tokenIn,
                _amountTokensIn
            );

            // checking slippage
            if (amounts[1] < _minAmountTokensOut) {
                revert("H"); // TODO: remove this line on production
                revert CerbySwapV1_OutputCerUsdAmountIsLowerThanMinimumSpecified();
            }

            // safely transferring tokens from sender to the vault
            _safeTransferFromHelper(
                _tokenIn,
                msg.sender,
                vaultAddressIn,
                _amountTokensIn
            );

            // swapping XXX ---> cerUSD
            _swap(
                _tokenIn,
                poolInBalancesBefore,
                0,
                amounts[1],
                _transferTo
            );

            return amounts;
        }

        // swaping cerUSD --> YYY
        address vaultAddressOut = _getCachedVaultCloneAddressByToken(
            _tokenOut
        );

        PoolBalances memory poolOutBalancesBefore;

        if (_tokenIn == CER_USD_TOKEN) {
            // getting pool balances before the swap
            poolOutBalancesBefore = _getPoolBalances(
                _tokenOut
            );

            // getting amountTokensOut
            amounts[1] = _getOutputExactCerUsdForTokens(
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
                vaultAddressOut,
                _amountTokensIn
            );

            // swapping cerUSD ---> YYY
            _swap(
                _tokenOut,
                poolOutBalancesBefore,
                amounts[1],
                0,
                _transferTo
            );

            return amounts;
        }

        // if (tokenIn != tokenOut && tokenIn != CER_USD_TOKEN && tokenOut != CER_USD_TOKEN)
        // swaping XXX --> cerUsd --> YYY (or XXX --> YYY)

        // getting pool balances before the swap
        poolInBalancesBefore = _getPoolBalances(
            _tokenIn
        );

        // getting amountTokensOut=
        uint256 amountCerUsdOut = _getOutputExactTokensForCerUsd(
            poolInBalancesBefore,
            _tokenIn,
            _amountTokensIn
        );

        // getting pool balances before the swap
        poolOutBalancesBefore = _getPoolBalances(
            _tokenOut
        );

        amounts[1] = _getOutputExactCerUsdForTokens(
            poolOutBalancesBefore,
            amountCerUsdOut
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
            vaultAddressIn,
            _amountTokensIn
        );

        // swapping XXX ---> cerUSD
        // keeping all output cerUSD in the contract without sending
        _swap(
            _tokenIn,
            poolInBalancesBefore,
            0,
            amountCerUsdOut,
            vaultAddressOut
        );

        // swapping cerUSD ---> YYY
        _swap(
            _tokenOut,
            poolOutBalancesBefore,
            amounts[1],
            0,
            _transferTo
        );

        return amounts;
    }

    function swapTokensForExactTokens(
        address _tokenIn,
        address _tokenOut,
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
        if (_tokenIn == _tokenOut) {
            revert("L"); // TODO: remove this line on production
            revert CerbySwapV1_SwappingTokenToSameTokenIsForbidden();
        }

        address vaultAddressIn = _getCachedVaultCloneAddressByToken(
            _tokenIn
        );

        uint256[] memory amounts = new uint256[](2);
        amounts[1] = _amountTokensOut;

        PoolBalances memory poolInBalancesBefore;

        // swapping XXX --> cerUSD
        if (_tokenOut == CER_USD_TOKEN) {
            // getting pool balances before the swap
            poolInBalancesBefore = _getPoolBalances(
                _tokenIn
            );

            // getting amountTokensOut
            amounts[0] = _getInputTokensForExactCerUsd(
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
                vaultAddressIn,
                amounts[0]
            );

            // swapping XXX ---> cerUSD
            _swap(
                _tokenIn,
                poolInBalancesBefore,
                0,
                _amountTokensOut,
                _transferTo
            );

            return amounts;
        }

        // swapping cerUSD --> YYY
        address vaultAddressOut = _getCachedVaultCloneAddressByToken(
            _tokenOut
        );

        PoolBalances memory poolOutBalancesBefore;

        if (_tokenIn == CER_USD_TOKEN) {
            // getting pool balances before the swap
            poolOutBalancesBefore = _getPoolBalances(
                _tokenOut
            );

            // getting amountTokensOut
            amounts[0] = _getInputCerUsdForExactTokens(
                poolOutBalancesBefore,
                _amountTokensOut
            );

            // checking slippage
            if (amounts[0] > _maxAmountTokensIn) {
                revert("J"); // TODO: remove this line on production
                revert CerbySwapV1_InputCerUsdAmountIsLargerThanMaximumSpecified();
            }

            // safely transferring tokens from sender to the vault
            _safeTransferFromHelper(
                _tokenIn,
                msg.sender,
                vaultAddressOut,
                amounts[0]
            );

            // swapping cerUSD ---> YYY
            _swap(
                _tokenOut,
                poolOutBalancesBefore,
                _amountTokensOut,
                0,
                _transferTo
            );

            return amounts;
        }

        // if (_tokenIn != CER_USD_TOKEN && _tokenOut != CER_USD_TOKEN && _tokenIn != _tokenOut)
        // swaping XXX --> cerUsd --> YYY (or XXX --> YYY)

        // getting pool balances before the swap
        poolOutBalancesBefore = _getPoolBalances(
            _tokenOut
        );

        // getting amountTokensOut
        uint256 amountCerUsdOut = _getInputCerUsdForExactTokens(
            poolOutBalancesBefore,
            _amountTokensOut
        );

        // amountCerUsdOut must be larger than 1 to avoid rounding errors
        if (amountCerUsdOut <= 1) {
            revert("U"); // TODO: remove this line on production
            revert CerbySwapV1_AmountOfCerUsdMustBeLargerThanOne();
        }

        // getting pool balances before the swap
        poolInBalancesBefore = _getPoolBalances(
            _tokenIn
        );

        amounts[0] = _getInputTokensForExactCerUsd(
            poolInBalancesBefore,
            _tokenIn,
            amountCerUsdOut
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
            vaultAddressIn,
            amounts[0]
        );

        // swapping XXX ---> cerUSD
        _swap(
            _tokenIn,
            poolInBalancesBefore,
            0,
            amountCerUsdOut,
            vaultAddressOut
        );

        // swapping cerUSD ---> YYY
        _swap(
            _tokenOut,
            poolOutBalancesBefore,
            _amountTokensOut,
            0,
            _transferTo
        );

        return amounts;
    }

    function _swap(
        address _token,
        PoolBalances memory _poolBalancesBefore,
        uint256 _amountTokensOut,
        uint256 _amountCerUsdOut,
        address _transferTo
    )
        private
    {
        PoolBalances memory poolBalancesAfter = _getPoolBalances(
            _token
        );

        // finding out how many amountCerUsdIn we received
        uint256 amountCerUsdIn = poolBalancesAfter.balanceCerUsd
            - _poolBalancesBefore.balanceCerUsd;

        // finding out how many amountTokensIn we received
        uint256 amountTokensIn = poolBalancesAfter.balanceToken
            - _poolBalancesBefore.balanceToken;

        // at least one of amountTokensIn or amountCerUsdIn must be larger than zero
        if (amountTokensIn + amountCerUsdIn <= 1) {
            revert("2");
            revert CerbySwapV1_AmountOfCerUsdOrTokensInMustBeLargerThanOne();
        }

        // checking if cerUsd credit is enough to cover this swap
        Pool storage pool = pools[cachedTokenValues[_token].poolId];

        if (
            pool.creditCerUsd < MAX_CER_USD_CREDIT &&
            uint256(pool.creditCerUsd) + amountCerUsdIn < _amountCerUsdOut
        ) {
            revert("Z");
            revert CerbySwapV1_CreditCerUsdMustNotBeBelowZero();
        }

        uint256 currentPeriod = _getCurrentPeriod();
        uint256 fee;

        {
            // calculating fees
            // if swap is ANY --> cerUSD, fee is calculated
            // else swap is cerUSD --> ANY, fee is zero
            if (amountCerUsdIn <= 1 && amountTokensIn > 1) {

                // updating cache while gas estimations to avoid out of gas error by artificially inflating gas limit
                // caching it for whole current period
                uint256 lastPeriodI = uint256(
                    pool.lastCachedTradePeriod
                );

                if (lastPeriodI != currentPeriod) {

                    // setting trade volume periods to 1
                    // iterating from (lastCachedTradePeriod+1) to currentPeriod (inclusive)
                    uint256 endPeriod = currentPeriod < lastPeriodI
                        ? currentPeriod + NUMBER_OF_TRADE_PERIODS
                        : currentPeriod;
                    
                    while(++lastPeriodI <= endPeriod) {
                        pool.tradeVolumePerPeriodInCerUsd[lastPeriodI % NUMBER_OF_TRADE_PERIODS] = 1;
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
            uint256 beforeKValueDenormed = _poolBalancesBefore.balanceToken
                * _poolBalancesBefore.balanceCerUsd
                * FEE_DENORM_SQUARED;

            // calculating new K value including trade fees
            // refer to 3.2.1 Adjustment for fee https://uniswap.org/whitepaper.pdf
            uint256 afterKValueDenormed = (
                    poolBalancesAfter.balanceCerUsd
                    * FEE_DENORM // = 1000 in uniswap wp
                        - amountCerUsdIn
                        * fee // = 3 in uniswap wp
                ) 
                * (
                    poolBalancesAfter.balanceToken 
                    * FEE_DENORM // = 1000 in uniswap wp
                        - amountTokensIn 
                        * fee // = 3 in uniswap wp
                );

            if (afterKValueDenormed < beforeKValueDenormed) {
                revert("1"); // TODO: remove on production
                revert CerbySwapV1_InvariantKValueMustBeSameOrIncreasedOnAnySwaps();
            }

            // updating creditCerUsd only if pool is user-created
            if (pool.creditCerUsd < MAX_CER_USD_CREDIT) {
                pool.creditCerUsd = uint128(
                    uint256(pool.creditCerUsd)
                        + amountCerUsdIn
                        - _amountCerUsdOut
                );
            }

            // updating 1 hour trade pool values
            // only for direction ANY --> cerUSD
            if (_amountCerUsdOut > TRADE_VOLUME_DENORM) {
                // or else amountCerUsdOut / TRADE_VOLUME_DENORM == 0
                // stores in 10xUSD value, up-to $40B per 4 hours per pair will be stored correctly
                uint256 updatedTradeVolume = _amountCerUsdOut
                    / TRADE_VOLUME_DENORM
                    + uint256(pool.tradeVolumePerPeriodInCerUsd[currentPeriod]); // if ANY --> cerUSD, then output is cerUSD only

                // handling overflow just in case
                pool.tradeVolumePerPeriodInCerUsd[currentPeriod] = updatedTradeVolume < type(uint40).max
                    ? uint40(updatedTradeVolume)
                    : type(uint40).max;
            }
        }

        // updating vault cache if needed
        address vault = _getCachedVaultCloneAddressByToken(
            _token
        );

        // safely transfering cerUSD
        _safeTransferFromHelper(
            CER_USD_TOKEN,
            vault,
            _transferTo,
            _amountCerUsdOut
        );

        // safely transfering tokens
        // and making sure exact amounts were actually transferred
        _safeTransferFromHelper(
            _token,
            vault,
            _transferTo,
            _amountTokensOut
        );

        // Swap event is needed to post in telegram channel
        emit Swap(
            _token,
            msg.sender,
            amountTokensIn,
            amountCerUsdIn,
            _amountTokensOut,
            _amountCerUsdOut,
            fee,
            _transferTo
        );

        // Sync event to update pool variables in the graph node
        emit Sync(
            _token,
            poolBalancesAfter.balanceToken,
            poolBalancesAfter.balanceCerUsd,
            pool.creditCerUsd
        );
    }
}
