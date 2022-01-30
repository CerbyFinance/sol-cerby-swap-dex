// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.11;

import "./CerbySwapV1_GetFunctions.sol";
import "./CerbySwapV1_SafeFunctions.sol";

abstract contract CerbySwapV1_SwapFunctions is
    CerbySwapV1_SafeFunctions,
    CerbySwapV1_GetFunctions
{
    function swapExactTokensForTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountTokensIn,
        uint256 minAmountTokensOut,
        uint256 expireTimestamp,
        address transferTo
    )
        public
        payable
        transactionIsNotExpired(expireTimestamp)
        returns (
            // checkForBots(msg.sender) // TODO: enable on production
            uint256,
            uint256
        )
    {
        // amountTokensIn must be larger than 1 to avoid rounding errors
        if (amountTokensIn <= 1) {
            revert("F"); // TODO: remove this line on production
            revert CerbySwapV1_AmountOfTokensMustBeLargerThanOne();
        }

        uint256 amountTokensOut;

        // swaping XXX --> cerUSD
        if (tokenIn != cerUsdToken && tokenOut == cerUsdToken) {
            // getting amountTokensOut
            amountTokensOut = _getOutputExactTokensForCerUsd(
                tokenIn,
                amountTokensIn
            );

            // checking slippage
            if (amountTokensOut < minAmountTokensOut) {
                revert("H"); // TODO: remove this line on production
                revert CerbySwapV1_OutputCerUsdAmountIsLowerThanMinimumSpecified();
            }

            // safely transferring tokens from sender to this contract
            // or doing nothing if msg.value specified correctly
            _safeTransferFromHelper(tokenIn, msg.sender, amountTokensIn);

            // swapping XXX ---> cerUSD
            lowLevelSwap(tokenIn, 0, amountTokensOut, transferTo);
            return (amountTokensIn, amountTokensOut);
        }

        // swaping cerUSD --> YYY
        if (tokenIn == cerUsdToken && tokenOut != cerUsdToken) {
            // getting amountTokensOut
            amountTokensOut = _getOutputExactCerUsdForTokens(
                tokenOut,
                amountTokensIn
            );

            // checking slippage
            if (amountTokensOut < minAmountTokensOut) {
                revert("i"); // TODO: remove this line on production
                revert CerbySwapV1_OutputTokensAmountIsLowerThanMinimumSpecified();
            }

            // safely transferring tokens from sender to this contract
            // or doing nothing if msg.value specified correctly
            _safeTransferFromHelper(tokenIn, msg.sender, amountTokensIn);

            // swapping cerUSD ---> YYY
            lowLevelSwap(tokenOut, amountTokensOut, 0, transferTo);

            return (amountTokensIn, amountTokensOut);
            // TODO: uncomment below
        }

        // swaping XXX --> cerUsd --> YYY (or XXX --> YYY)
        if (
            tokenIn != cerUsdToken &&
            tokenIn != cerUsdToken &&
            tokenIn != tokenOut
        ) {
            // getting amountTokensOut=
            uint256 amountCerUsdOut = _getOutputExactTokensForCerUsd(
                tokenIn,
                amountTokensIn
            );

            amountTokensOut = _getOutputExactCerUsdForTokens(
                tokenOut,
                amountCerUsdOut
            );

            // checking slippage
            if (amountTokensOut < minAmountTokensOut) {
                revert("i"); // TODO: remove this line on production
                revert CerbySwapV1_OutputTokensAmountIsLowerThanMinimumSpecified();
            }

            // safely transferring tokens from sender to this contract
            // or doing nothing if msg.value specified correctly
            _safeTransferFromHelper(tokenIn, msg.sender, amountTokensIn);

            // swapping XXX ---> cerUSD
            // keeping all output cerUSD in the contract without sending
            lowLevelSwap(tokenIn, 0, amountCerUsdOut, address(this));

            // swapping cerUSD ---> YYY
            lowLevelSwap(tokenOut, amountTokensOut, 0, transferTo);
            return (amountTokensIn, amountTokensOut);
        }

        // tokenIn == tokenOut clause
        revert("L"); // TODO: remove this line on production
        revert CerbySwapV1_SwappingTokenToSameTokenIsForbidden();
    }

    function swapTokensForExactTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountTokensOut,
        uint256 maxAmountTokensIn,
        uint256 expireTimestamp,
        address transferTo
    )
        public
        payable
        transactionIsNotExpired(expireTimestamp)
        returns (
            // checkForBots(msg.sender) // TODO: enable on production
            uint256,
            uint256
        )
    {
        uint256 amountTokensIn;

        // swapping XXX --> cerUSD
        if (tokenIn != cerUsdToken && tokenOut == cerUsdToken) {
            // getting amountTokensOut
            amountTokensIn = _getInputTokensForExactCerUsd(
                tokenIn,
                amountTokensOut
            );

            // checking slippage
            if (amountTokensIn > maxAmountTokensIn) {
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
            _safeTransferFromHelper(tokenIn, msg.sender, amountTokensIn);

            // swapping XXX ---> cerUSD
            lowLevelSwap(tokenIn, 0, amountTokensOut, transferTo);

            return (amountTokensIn, amountTokensOut);
        }

        // swapping cerUSD --> YYY
        if (tokenIn == cerUsdToken && tokenOut != cerUsdToken) {
            // getting amountTokensOut
            amountTokensIn = _getInputCerUsdForExactTokens(
                tokenOut,
                amountTokensOut
            );

            // checking slippage
            if (amountTokensIn > maxAmountTokensIn) {
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
            _safeTransferFromHelper(tokenIn, msg.sender, amountTokensIn);

            // swapping cerUSD ---> YYY
            lowLevelSwap(tokenOut, amountTokensOut, 0, transferTo);

            return (amountTokensIn, amountTokensOut);
        }

        // swaping XXX --> cerUsd --> YYY (or XXX --> YYY)
        if (
            tokenIn != cerUsdToken &&
            tokenOut != cerUsdToken &&
            tokenIn != tokenOut
        ) {
            // getting amountTokensOut
            uint256 amountCerUsdOut = _getInputCerUsdForExactTokens(
                tokenOut,
                amountTokensOut
            );

            // amountCerUsdOut must be larger than 1 to avoid rounding errors
            if (amountCerUsdOut <= 1) {
                revert("U"); // TODO: remove this line on production
                revert CerbySwapV1_AmountOfCerUsdMustBeLargerThanOne();
            }

            amountTokensIn = _getInputTokensForExactCerUsd(
                tokenIn,
                amountCerUsdOut
            );

            // amountTokensIn must be larger than 1 to avoid rounding errors
            if (amountTokensIn <= 1) {
                revert("U"); // TODO: remove this line on production
                revert CerbySwapV1_AmountOfCerUsdMustBeLargerThanOne();
            }

            // checking slippage
            if (amountTokensIn > maxAmountTokensIn) {
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
            _safeTransferFromHelper(tokenIn, msg.sender, amountTokensIn);

            // swapping XXX ---> cerUSD
            lowLevelSwap(tokenIn, 0, amountCerUsdOut, address(this));

            // swapping cerUSD ---> YYY
            lowLevelSwap(tokenOut, amountTokensOut, 0, transferTo);

            return (amountTokensIn, amountTokensOut);
        }

        // tokenIn == tokenOut clause
        revert("L"); // TODO: remove this line on production
        revert CerbySwapV1_SwappingTokenToSameTokenIsForbidden();
    }

    function lowLevelSwap(
        address token,
        uint256 amountTokensOut,
        uint256 amountCerUsdOut,
        address transferTo
    ) public payable tokenMustExistInPool(token) {
        Pool storage pool = pools[tokenToPoolId[token]];

        // finding out how many amountCerUsdIn we received
        uint256 amountCerUsdIn = _getTokenBalance(cerUsdToken) -
            totalCerUsdBalance;

        // finding out how many amountTokensIn we received
        uint256 amountTokensIn = _getTokenBalance(token) - pool.balanceToken;
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
                pool.creditCerUsd + amountCerUsdIn < amountCerUsdOut
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
                amountCerUsdOut;
            uint256 _balanceCerUsd = uint256(pool.balanceCerUsd) +
                amountCerUsdIn -
                amountCerUsdOut;
            uint256 _balanceToken = uint256(pool.balanceToken) +
                amountTokensIn -
                amountTokensOut;

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
                    amountCerUsdOut;
            }
        }

        // updating 1 hour trade pool values
        // only for direction ANY --> cerUSD
        uint256 currentPeriod = _getCurrentPeriod();
        uint256 nextPeriod = (currentPeriod + 1) % NUMBER_OF_TRADE_PERIODS;
        if (amountCerUsdOut > TRADE_VOLUME_DENORM) {
            // or else amountCerUsdOut / TRADE_VOLUME_DENORM == 0
            // stores in 10xUSD value, up-to $40B per 4 hours per pair will be stored correctly
            uint256 updatedTradeVolume = uint256(
                pool.tradeVolumePerPeriodInCerUsd[currentPeriod]
            ) + amountCerUsdOut / TRADE_VOLUME_DENORM; // if ANY --> cerUSD, then output is cerUSD only

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
        _safeTransferHelper(token, transferTo, amountTokensOut, true);

        // safely transfering cerUSD
        _safeTransferHelper(cerUsdToken, transferTo, amountCerUsdOut, true);

        // Swap event is needed to post in telegram channel
        emit Swap(
            token,
            msg.sender,
            amountTokensIn,
            amountCerUsdIn,
            amountTokensOut,
            amountCerUsdOut,
            FEE_DENORM - oneMinusFee, // = fee * FEE_DENORM
            transferTo
        );

        // Sync event to update pool variables in the graph node
        emit Sync(
            token,
            pool.balanceToken,
            pool.balanceCerUsd,
            pool.creditCerUsd
        );
    }
}
