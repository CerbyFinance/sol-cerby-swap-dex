// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.11;

import "./CerbySwapV1_GetFunctions.sol";
import "./CerbySwapV1_SafeFunctions.sol";

abstract contract CerbySwapV1_SwapFunctions is
    CerbySwapV1_SafeFunctions,
    CerbySwapV1_GetFunctions
{
    function swapExactTokensForTokens(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountTokensIn,
        uint256 _minAmountTokensOut,
        uint256 _expireTimestamp,
        address _transferTo
    )
        public
        payable
        transactionIsNotExpired(_expireTimestamp)
        returns (
            // checkForBots(msg.sender) // TODO: enable on production
            uint256,
            uint256
        )
    {
        // amountTokensIn must be larger than 1 to avoid rounding errors
        if (_amountTokensIn <= 1) {
            revert("F"); // TODO: remove this line on production
            revert CerbySwapV1_AmountOfTokensMustBeLargerThanOne();
        }

        uint256 amountTokensOut;

        // swaping XXX --> cerUSD
        if (_tokenIn != cerUsdToken && _tokenOut == cerUsdToken) {
            // getting amountTokensOut
            amountTokensOut = _getOutputExactTokensForCerUsd(
                _tokenIn,
                _amountTokensIn
            );

            // checking slippage
            if (amountTokensOut < _minAmountTokensOut) {
                revert("H"); // TODO: remove this line on production
                revert CerbySwapV1_OutputCerUsdAmountIsLowerThanMinimumSpecified();
            }

            // safely transferring tokens from sender to this contract
            // or doing nothing if msg.value specified correctly
            _safeTransferFromHelper(
                _tokenIn,
                msg.sender,
                _amountTokensIn
            );

            // swapping XXX ---> cerUSD
            lowLevelSwap(
                _tokenIn,
                0,
                amountTokensOut,
                _transferTo
            );

            return (_amountTokensIn, amountTokensOut);
        }

        // swaping cerUSD --> YYY
        if (_tokenIn == cerUsdToken && _tokenOut != cerUsdToken) {
            // getting amountTokensOut
            amountTokensOut = _getOutputExactCerUsdForTokens(
                _tokenOut,
                _amountTokensIn
            );

            // checking slippage
            if (amountTokensOut < _minAmountTokensOut) {
                revert("i"); // TODO: remove this line on production
                revert CerbySwapV1_OutputTokensAmountIsLowerThanMinimumSpecified();
            }

            // safely transferring tokens from sender to this contract
            // or doing nothing if msg.value specified correctly
            _safeTransferFromHelper(
                _tokenIn,
                msg.sender,
                _amountTokensIn
            );

            // swapping cerUSD ---> YYY
            lowLevelSwap(
                _tokenOut,
                amountTokensOut,
                0,
                _transferTo
            );

            return (_amountTokensIn, amountTokensOut);
            // TODO: uncomment below
        }

        // swaping XXX --> cerUsd --> YYY (or XXX --> YYY)
        if (
            _tokenIn != cerUsdToken &&
            _tokenIn != cerUsdToken && // Q: ??
            _tokenIn != _tokenOut
        ) {
            // getting amountTokensOut=
            uint256 amountCerUsdOut = _getOutputExactTokensForCerUsd(
                _tokenIn,
                _amountTokensIn
            );

            amountTokensOut = _getOutputExactCerUsdForTokens(
                _tokenOut,
                amountCerUsdOut
            );

            // checking slippage
            if (amountTokensOut < _minAmountTokensOut) {
                revert("i"); // TODO: remove this line on production
                revert CerbySwapV1_OutputTokensAmountIsLowerThanMinimumSpecified();
            }

            // safely transferring tokens from sender to this contract
            // or doing nothing if msg.value specified correctly
            _safeTransferFromHelper(
                _tokenIn,
                msg.sender,
                _amountTokensIn
            );

            // swapping XXX ---> cerUSD
            // keeping all output cerUSD in the contract without sending
            lowLevelSwap(
                _tokenIn,
                0,
                amountCerUsdOut,
                address(this)
            );

            // swapping cerUSD ---> YYY
            lowLevelSwap(
                _tokenOut,
                amountTokensOut,
                0,
                _transferTo
            );

            return (_amountTokensIn, amountTokensOut);
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
        public // Q: external?
        payable // payable?
        transactionIsNotExpired(_expireTimestamp)
        returns (
            // checkForBots(msg.sender) // TODO: enable on production
            uint256,
            uint256
        )
    {
        if (_tokenIn == _tokenOut) return;

        uint256 amountTokensIn;

        // swapping XXX --> cerUSD
        if (_tokenOut == cerUsdToken) {
            // getting amountTokensOut
            amountTokensIn = _getInputTokensForExactCerUsd(
                _tokenIn,
                _amountTokensOut
            );

            // checking slippage
            if (amountTokensIn > _maxAmountTokensIn) {
                revert("K"); // TODO: remove this line on production
                revert CerbySwapV1_InputTokensAmountIsLargerThanMaximumSpecified();
            }

            // amountTokensIn must be larger than 1 to avoid rounding errors
            if (amountTokensIn <= 1) {
                revert("F"); // TODO: remove this line on production
                revert CerbySwapV1_AmountOfTokensMustBeLargerThanOne();
            }

            // safely transferring tokens from sender to this contract
            // or doing nothing if msg.value specified correctly
            _safeTransferFromHelper(
                _tokenIn,
                msg.sender,
                amountTokensIn
            );

            // swapping XXX ---> cerUSD
            lowLevelSwap(
                _tokenIn,
                0,
                _amountTokensOut,
                _transferTo
            );

            return (amountTokensIn, _amountTokensOut);
        }

        // swapping cerUSD --> YYY
        if (_tokenIn == cerUsdToken) {
            // getting amountTokensOut
            amountTokensIn = _getInputCerUsdForExactTokens(
                _tokenOut,
                _amountTokensOut
            );

            // checking slippage
            if (amountTokensIn > _maxAmountTokensIn) {
                revert("J"); // TODO: remove this line on production
                revert CerbySwapV1_InputCerUsdAmountIsLargerThanMaximumSpecified();
            }

            // amountTokensIn must be larger than 1 to avoid rounding errors
            if (amountTokensIn <= 1) {
                revert("U"); // TODO: remove this line on production
                revert CerbySwapV1_AmountOfCerUsdMustBeLargerThanOne();
            }

            // safely transferring tokens from sender to this contract
            // or doing nothing if msg.value specified correctly
            _safeTransferFromHelper(
                _tokenIn,
                msg.sender,
                amountTokensIn
            );

            // swapping cerUSD ---> YYY
            lowLevelSwap(
                _tokenOut,
                _amountTokensOut,
                0,
                _transferTo
            );

            return (amountTokensIn, _amountTokensOut);
        }

        // getting amountTokensOut
        uint256 amountCerUsdOut = _getInputCerUsdForExactTokens(
            _tokenOut,
            _amountTokensOut
        );

        // amountCerUsdOut must be larger than 1 to avoid rounding errors
        if (amountCerUsdOut <= 1) {
            revert("U"); // TODO: remove this line on production
            revert CerbySwapV1_AmountOfCerUsdMustBeLargerThanOne();
        }

        amountTokensIn = _getInputTokensForExactCerUsd(
            _tokenIn,
            amountCerUsdOut
        );

        // amountTokensIn must be larger than 1 to avoid rounding errors
        if (amountTokensIn <= 1) {
            revert("U"); // TODO: remove this line on production
            revert CerbySwapV1_AmountOfCerUsdMustBeLargerThanOne();
        }

        // checking slippage
        if (amountTokensIn > _maxAmountTokensIn) {
            revert("K"); // TODO: remove this line on production
            revert CerbySwapV1_InputTokensAmountIsLargerThanMaximumSpecified();
        }

        // amountTokensIn must be larger than 1 to avoid rounding errors
        if (amountTokensIn <= 1) {
            revert("F"); // TODO: remove this line on production
            revert CerbySwapV1_AmountOfTokensMustBeLargerThanOne();
        }

        // safely transferring tokens from sender to this contract
        // or doing nothing if msg.value specified correctly
        _safeTransferFromHelper(
            _tokenIn,
            msg.sender,
            amountTokensIn
        );

        // swapping XXX ---> cerUSD
        lowLevelSwap(
            _tokenIn,
            0,
            amountCerUsdOut,
            address(this)
        );

        // swapping cerUSD ---> YYY
        lowLevelSwap(
            _tokenOut,
            _amountTokensOut,
            0,
            _transferTo
        );

        return (amountTokensIn, _amountTokensOut);
    }

    function lowLevelSwap(
        address _token,
        uint256 _amountTokensOut,
        uint256 _amountCerUsdOut,
        address _transferTo
    )
        public
        payable
        tokenMustExistInPool(_token)
    {
        Pool storage pool = pools[tokenToPoolId[_token]];

        // finding out how many amountCerUsdIn we received
        uint256 amountCerUsdIn = _getTokenBalance(cerUsdToken) -
            totalCerUsdBalance;

        // finding out how many amountTokensIn we received
        uint256 amountTokensIn = _getTokenBalance(_token) - pool.balanceToken;
        if (amountTokensIn + amountCerUsdIn <= 1) {
            revert("2");
            revert CerbySwapV1_AmountOfCerUsdOrTokensInMustBeLargerThanOne();
        }

        // calculating fees
        // if swap is ANY --> cerUSD, fee is calculated
        // if swap is cerUSD --> ANY, fee is zero
        uint256 oneMinusFee = amountCerUsdIn > 1 && amountTokensIn <= 1
            ? FEE_DENORM
            : _getCurrentOneMinusFeeBasedOnTrades(pool);

        {
            // scope to avoid stack too deep error

            // checking if cerUsd credit is enough to cover this swap
            if (
                pool.creditCerUsd < type(uint256).max &&
                pool.creditCerUsd + amountCerUsdIn < _amountCerUsdOut
            ) {
                revert("Z");
                revert CerbySwapV1_CreditCerUsdMustNotBeBelowZero();
            }

            // calculating old K value including trade fees (multiplied by FEE_DENORM^2)
            uint256 beforeKValueDenormed = uint256(pool.balanceCerUsd) *
                uint256(pool.balanceToken) *
                FEE_DENORM_SQUARED;

            // calculating new pool values
            uint256 _totalCerUsdBalance = totalCerUsdBalance +
                amountCerUsdIn -
                _amountCerUsdOut;
            uint256 _balanceCerUsd = uint256(pool.balanceCerUsd) +
                amountCerUsdIn -
                _amountCerUsdOut;
            uint256 _balanceToken = uint256(pool.balanceToken) +
                amountTokensIn -
                _amountTokensOut;

            // calculating new K value including trade fees
            uint256 afterKValueDenormed = (_balanceCerUsd *
                FEE_DENORM -
                amountCerUsdIn *
                (FEE_DENORM - oneMinusFee)) *
                (_balanceToken *
                    FEE_DENORM -
                    amountTokensIn *
                    (FEE_DENORM - oneMinusFee));
            if (afterKValueDenormed < beforeKValueDenormed) {
                revert("1");
                revert CerbySwapV1_InvariantKValueMustBeSameOrIncreasedOnAnySwaps();
            }

            // updating pool values
            totalCerUsdBalance = _totalCerUsdBalance;
            pool.balanceCerUsd = uint128(_balanceCerUsd);
            pool.balanceToken = uint128(_balanceToken);

            // updating creditCerUsd only if pool is user-created
            if (pool.creditCerUsd < type(uint256).max) {
                pool.creditCerUsd =
                    pool.creditCerUsd +
                    amountCerUsdIn -
                    _amountCerUsdOut;
            }
        }

        // updating 1 hour trade pool values
        // only for direction ANY --> cerUSD
        uint256 currentPeriod = _getCurrentPeriod();
        uint256 nextPeriod = (currentPeriod + 1) % NUMBER_OF_TRADE_PERIODS;
        if (_amountCerUsdOut > TRADE_VOLUME_DENORM) {
            // or else amountCerUsdOut / TRADE_VOLUME_DENORM == 0
            // stores in 10xUSD value, up-to $40B per 4 hours per pair will be stored correctly
            uint256 updatedTradeVolume = uint256(
                pool.tradeVolumePerPeriodInCerUsd[currentPeriod]
            ) + _amountCerUsdOut / TRADE_VOLUME_DENORM; // if ANY --> cerUSD, then output is cerUSD only

            // handling overflow just in case
            pool.tradeVolumePerPeriodInCerUsd[
                currentPeriod
            ] = updatedTradeVolume < type(uint32).max
                ? uint32(updatedTradeVolume)
                : type(uint32).max;
        }

        // clearing next 1 hour trade value
        if (pool.tradeVolumePerPeriodInCerUsd[nextPeriod] > 1) {
            // gas saving to not zero the field
            pool.tradeVolumePerPeriodInCerUsd[nextPeriod] = 1;
        }

        // safely transfering tokens
        // and making sure exact amounts were actually transferred
        _safeTransferHelper(_token, _transferTo, _amountTokensOut, true);

        // safely transfering cerUSD
        _safeTransferHelper(cerUsdToken, _transferTo, _amountCerUsdOut, true);

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
            pool.balanceToken,
            pool.balanceCerUsd,
            pool.creditCerUsd
        );
    }
}
