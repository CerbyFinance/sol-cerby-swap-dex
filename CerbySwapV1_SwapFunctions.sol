// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.11;

import "./CerbySwapV1_LiquidityFunctions.sol";
import "./interfaces/ICerbyTokenMinterBurner.sol";

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
        returns (
            // checkForBots(msg.sender) // TODO: enable on production
            uint256[] memory
        )
    {
        // amountTokensIn must be larger than 1 to avoid rounding errors
        if (_amountTokensIn <= 1) {
            revert("F"); // TODO: remove this line on production
            revert CerbySwapV1_AmountOfTokensMustBeLargerThanOne();
        }

        address vaultAddressIn = pools[tokenToPoolId[_tokenIn]].vaultAddress;
        address vaultAddressOut = pools[tokenToPoolId[_tokenOut]].vaultAddress;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = _amountTokensIn;

        // swaping XXX --> cerUSD
        if (_tokenIn != cerUsdToken && _tokenOut == cerUsdToken) {
            // getting pool balances before the swap
            PoolBalances memory poolInBalancesBefore = _getPoolBalances(
                _tokenIn,
                vaultAddressIn
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
            _swap(_tokenIn, poolInBalancesBefore, 0, amounts[1], _transferTo);

            return amounts;
        }

        // swaping cerUSD --> YYY
        if (_tokenIn == cerUsdToken && _tokenOut != cerUsdToken) {
            // getting pool balances before the swap
            PoolBalances memory poolOutBalancesBefore = _getPoolBalances(
                _tokenOut,
                vaultAddressOut
            );

            // getting amountTokensOut
            amounts[1] = _getOutputExactCerUsdForTokens(
                poolOutBalancesBefore,
                _tokenOut,
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
            _swap(_tokenOut, poolOutBalancesBefore, amounts[1], 0, _transferTo);

            return amounts;
        }

        // swaping XXX --> cerUsd --> YYY (or XXX --> YYY)
        if (
            _tokenIn != cerUsdToken &&
            _tokenOut != cerUsdToken &&
            _tokenIn != _tokenOut
        ) {
            // getting pool balances before the swap
            PoolBalances memory poolInBalancesBefore = _getPoolBalances(
                _tokenIn,
                vaultAddressIn
            );

            // getting amountTokensOut=
            uint256 amountCerUsdOut = _getOutputExactTokensForCerUsd(
                poolInBalancesBefore,
                _tokenIn,
                _amountTokensIn
            );

            // getting pool balances before the swap
            PoolBalances memory poolOutBalancesBefore = _getPoolBalances(
                _tokenOut,
                vaultAddressOut
            );

            amounts[1] = _getOutputExactCerUsdForTokens(
                poolOutBalancesBefore,
                _tokenOut,
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
            _swap(_tokenOut, poolOutBalancesBefore, amounts[1], 0, _transferTo);

            return amounts;
        }

        // tokenIn == tokenOut clause
        revert("L"); // TODO: remove this line on production
        revert CerbySwapV1_SwappingTokenToSameTokenIsForbidden();
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
        returns (
            // checkForBots(msg.sender) // TODO: enable on production
            uint256[] memory
        )
    {
        address vaultAddressIn = pools[tokenToPoolId[_tokenIn]].vaultAddress;
        address vaultAddressOut = pools[tokenToPoolId[_tokenOut]].vaultAddress;

        uint256[] memory amounts = new uint256[](2);
        amounts[1] = _amountTokensOut;

        // swapping XXX --> cerUSD
        if (_tokenIn != cerUsdToken && _tokenOut == cerUsdToken) {
            // getting pool balances before the swap
            PoolBalances memory poolInBalancesBefore = _getPoolBalances(
                _tokenIn,
                vaultAddressIn
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

            // amountTokensIn must be larger than 1 to avoid rounding errors
            if (amounts[0] <= 1) {
                revert("F"); // TODO: remove this line on production
                revert CerbySwapV1_AmountOfTokensMustBeLargerThanOne();
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
        if (_tokenIn == cerUsdToken && _tokenOut != cerUsdToken) {
            // getting pool balances before the swap
            PoolBalances memory poolOutBalancesBefore = _getPoolBalances(
                _tokenOut,
                vaultAddressOut
            );

            // getting amountTokensOut
            amounts[0] = _getInputCerUsdForExactTokens(
                poolOutBalancesBefore,
                _tokenOut,
                _amountTokensOut
            );

            // checking slippage
            if (amounts[0] > _maxAmountTokensIn) {
                revert("J"); // TODO: remove this line on production
                revert CerbySwapV1_InputCerUsdAmountIsLargerThanMaximumSpecified();
            }

            // amountTokensIn must be larger than 1 to avoid rounding errors
            if (amounts[0] <= 1) {
                revert("U"); // TODO: remove this line on production
                revert CerbySwapV1_AmountOfCerUsdMustBeLargerThanOne();
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

        // swaping XXX --> cerUsd --> YYY (or XXX --> YYY)
        if (
            _tokenIn != cerUsdToken &&
            _tokenOut != cerUsdToken &&
            _tokenIn != _tokenOut
        ) {
            // getting pool balances before the swap
            PoolBalances memory poolOutBalancesBefore = _getPoolBalances(
                _tokenOut,
                vaultAddressOut
            );

            // getting amountTokensOut
            uint256 amountCerUsdOut = _getInputCerUsdForExactTokens(
                poolOutBalancesBefore,
                _tokenOut,
                _amountTokensOut
            );

            // amountCerUsdOut must be larger than 1 to avoid rounding errors
            if (amountCerUsdOut <= 1) {
                revert("U"); // TODO: remove this line on production
                revert CerbySwapV1_AmountOfCerUsdMustBeLargerThanOne();
            }

            // getting pool balances before the swap
            PoolBalances memory poolInBalancesBefore = _getPoolBalances(
                _tokenIn,
                vaultAddressIn
            );

            amounts[0] = _getInputTokensForExactCerUsd(
                poolInBalancesBefore,
                _tokenIn,
                amountCerUsdOut
            );

            // amountTokensIn must be larger than 1 to avoid rounding errors
            if (amounts[0] <= 1) {
                revert("U"); // TODO: remove this line on production
                revert CerbySwapV1_AmountOfTokensMustBeLargerThanOne();
            }

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

        // tokenIn == tokenOut clause
        revert("L"); // TODO: remove this line on production
        revert CerbySwapV1_SwappingTokenToSameTokenIsForbidden();
    }

    function _swap(
        address _token,
        PoolBalances memory _poolBalancesBefore,
        uint256 _amountTokensOut,
        uint256 _amountCerUsdOut,
        address _transferTo
    ) private tokenMustExistInPool(_token) {
        Pool storage pool = pools[tokenToPoolId[_token]];

        PoolBalances memory poolBalancesAfter = _getPoolBalances(
            _token,
            pool.vaultAddress
        );

        // finding out how many amountCerUsdIn we received
        uint256 amountCerUsdIn = poolBalancesAfter.balanceCerUsd -
            _poolBalancesBefore.balanceCerUsd;

        // finding out how many amountTokensIn we received
        uint256 amountTokensIn = poolBalancesAfter.balanceToken -
            _poolBalancesBefore.balanceToken;
        if (amountTokensIn + amountCerUsdIn <= 1) {
            revert("2");
            revert CerbySwapV1_AmountOfCerUsdOrTokensInMustBeLargerThanOne();
        }

        // checking if cerUsd credit is enough to cover this swap
        if (
            pool.creditCerUsd < MAX_CER_USD_CREDIT &&
            uint256(pool.creditCerUsd) + amountCerUsdIn < _amountCerUsdOut
        ) {
            revert("Z");
            revert CerbySwapV1_CreditCerUsdMustNotBeBelowZero();
        }

        // calculating fees
        // if swap is ANY --> cerUSD, fee is calculated
        // if swap is cerUSD --> ANY, fee is zero
        uint256 currentPeriod = _getCurrentPeriod();
        uint256 oneMinusFee = FEE_DENORM;

        // for direction XXX --> cerUSD we apply trade fees
        if (_amountCerUsdOut > 0) {
            // if oneMinusFee isn't cached yet for currentPeriod => we cache it first
            // to avoid out of gas errors we inflate gas estimations by always updating cache
            if (
                oneMinusFeeCached[_token][currentPeriod] == 0 ||
                tx.gasprice == 0
            ) {
                oneMinusFeeCached[_token][
                    currentPeriod
                ] = _getCurrentOneMinusFeeBasedOnTrades(
                    _token,
                    _poolBalancesBefore
                );
            }
            // getting cached value from storage
            oneMinusFee = oneMinusFeeCached[_token][currentPeriod];
        }
        {
            // calculating new K value including trade fees
            uint256 afterKValueDenormed = (poolBalancesAfter.balanceCerUsd *
                FEE_DENORM -
                amountCerUsdIn *
                (FEE_DENORM - oneMinusFee)) *
                (poolBalancesAfter.balanceToken *
                    FEE_DENORM -
                    amountTokensIn *
                    (FEE_DENORM - oneMinusFee));

            // comparing new K value to old K value
            if (
                afterKValueDenormed <
                _poolBalancesBefore.balanceToken *
                    _poolBalancesBefore.balanceCerUsd *
                    FEE_DENORM_SQUARED
            ) {
                revert("1");
                revert CerbySwapV1_InvariantKValueMustBeSameOrIncreasedOnAnySwaps();
            }

            // updating creditCerUsd only if pool is user-created
            if (pool.creditCerUsd < MAX_CER_USD_CREDIT) {
                pool.creditCerUsd = uint128(
                    uint256(pool.creditCerUsd) +
                        amountCerUsdIn -
                        _amountCerUsdOut
                );
            }

            // updating 1 hour trade pool values
            // only for direction ANY --> cerUSD
            if (_amountCerUsdOut > 1) {
                hourlyTradeVolumeInCerUsd[_token][
                    currentPeriod
                ] += _amountCerUsdOut;
            }
        }
        // safely transfering tokens
        // and making sure exact amounts were actually transferred
        _safeTransferFromHelper(
            _token,
            pool.vaultAddress,
            _transferTo,
            _amountTokensOut
        );

        // safely transfering cerUSD
        _safeTransferFromHelper(
            cerUsdToken,
            pool.vaultAddress,
            _transferTo,
            _amountCerUsdOut
        );

        // Swap event is needed to post in telegram channel
        emit Swap(
            _token,
            msg.sender,
            amountTokensIn,
            amountCerUsdIn,
            _amountTokensOut,
            _amountCerUsdOut,
            FEE_DENORM - oneMinusFee, // = fee * FEE_DENORM
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
