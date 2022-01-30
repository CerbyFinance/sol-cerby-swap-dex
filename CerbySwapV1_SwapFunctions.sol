// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.11;

import "./CerbySwapV1_GetFunctions.sol";
import "./CerbySwapV1_SafeFunctions.sol";

abstract contract CerbySwapV1_SwapFunctions is CerbySwapV1_SafeFunctions, CerbySwapV1_GetFunctions  {

    function swapExactTokensForTokens(
        address tokenIn,
        address tokenOut,
        uint amountTokensIn,
        uint minAmountTokensOut,
        uint expireTimestamp,
        address transferTo
    )
        public
        payable
        transactionIsNotExpired(expireTimestamp)
        // checkForBots(msg.sender) // TODO: enable on production
        returns (uint, uint)
    {

        // amountTokensIn must be larger than 1 to avoid rounding errors
        if (
            amountTokensIn <= 1
        ) {
            revert("F"); // TODO: remove this line on production
            revert CerbySwapV1_AmountOfTokensMustBeLargerThanOne();
        }
    
        address fromAddress = msg.sender;
        uint amountTokensOut;
        if (tokenIn != cerUsdToken && tokenOut == cerUsdToken) {

            // getting amountTokensOut
            amountTokensOut = _getOutputExactTokensForCerUsd(tokenIn, amountTokensIn);

            // checking slippage
            if (
                amountTokensOut < minAmountTokensOut
            ) {
                revert("H"); // TODO: remove this line on production
                revert CerbySwapV1_OutputCerUsdAmountIsLowerThanMinimumSpecified();
            }

            // safely transferring tokens from sender to this contract
            // or doing nothing if msg.value specified correctly
            _safeTransferFromHelper(tokenIn, fromAddress, amountTokensIn);

            // swapping XXX ---> cerUSD
            lowLevelSwap(
                tokenIn,
                0,
                amountTokensOut,
                transferTo
            );
        } else if (tokenIn == cerUsdToken && tokenOut != cerUsdToken) {

            // getting amountTokensOut
            amountTokensOut = _getOutputExactCerUsdForTokens(tokenOut, amountTokensIn);

            // checking slippage
            if (
                amountTokensOut < minAmountTokensOut
            ) {
                revert("i"); // TODO: remove this line on production
                revert CerbySwapV1_OutputTokensAmountIsLowerThanMinimumSpecified();
            }
            
            // safely transferring tokens from sender to this contract
            // or doing nothing if msg.value specified correctly
            _safeTransferFromHelper(tokenIn, fromAddress, amountTokensIn);

            // swapping cerUSD ---> YYY
            lowLevelSwap(
                tokenOut,
                amountTokensOut,
                0,
                transferTo
            );
        // TODO: uncomment below
        } else if (tokenIn != cerUsdToken && tokenIn != cerUsdToken /*&& tokenIn != tokenOut*/) {

            // getting amountTokensOut=
            uint amountCerUsdOut = _getOutputExactTokensForCerUsd(tokenIn, amountTokensIn);

            amountTokensOut = _getOutputExactCerUsdForTokens(tokenOut, amountCerUsdOut);

            // checking slippage
            if (
                amountTokensOut < minAmountTokensOut
            ) {
                revert("i"); // TODO: remove this line on production
                revert CerbySwapV1_OutputTokensAmountIsLowerThanMinimumSpecified();
            }

            // safely transferring tokens from sender to this contract
            // or doing nothing if msg.value specified correctly
            _safeTransferFromHelper(tokenIn, fromAddress, amountTokensIn);

            // swapping XXX ---> cerUSD
            lowLevelSwap(
                tokenIn,
                0,
                amountCerUsdOut,
                address(this)
            );

            // swapping cerUSD ---> YYY
            lowLevelSwap(
                tokenOut,
                amountTokensOut,
                0,
                transferTo
            );
        } else {
            revert("L"); // TODO: remove this line on production
            revert CerbySwapV1_SwappingTokenToSameTokenIsForbidden(); // TODO: don't forget uncomment above!
        }
        

        return (amountTokensIn, amountTokensOut);
    }

    
    function swapTokensForExactTokens(
        address tokenIn,
        address tokenOut,
        uint amountTokensOut,
        uint maxAmountTokensIn,
        uint expireTimestamp,
        address transferTo
    )
        public
        payable
        transactionIsNotExpired(expireTimestamp)
        // checkForBots(msg.sender) // TODO: enable on production
        returns (uint, uint)
    {
        address fromAddress = msg.sender;
        uint amountTokensIn;
        if (tokenIn != cerUsdToken && tokenOut == cerUsdToken) {

            // getting amountTokensOut
            amountTokensIn = _getInputTokensForExactCerUsd(tokenIn, amountTokensOut);

            // checking slippage
            if (
                amountTokensIn > maxAmountTokensIn
            ) {
                revert("K"); // TODO: remove this line on production
                revert CerbySwapV1_InputTokensAmountIsLargerThanMaximumSpecified();
            }

            // amountTokensIn must be larger than 1 to avoid rounding errors
            if (
                amountTokensIn <= 1
            ) {
                revert("F"); // TODO: remove this line on production
                revert CerbySwapV1_AmountOfTokensMustBeLargerThanOne();
            }

            // safely transferring tokens from sender to this contract
            // or doing nothing if msg.value specified correctly
            _safeTransferFromHelper(tokenIn, fromAddress, amountTokensIn);

            // swapping XXX ---> cerUSD
            lowLevelSwap(
                tokenIn,
                0,
                amountTokensOut,
                transferTo
            );
        } else if (tokenIn == cerUsdToken && tokenOut != cerUsdToken) {

            // getting amountTokensOut
            amountTokensIn = _getInputCerUsdForExactTokens(tokenOut, amountTokensOut);

            // checking slippage
            if (
                amountTokensIn > maxAmountTokensIn
            ) {
                revert("J"); // TODO: remove this line on production
                revert CerbySwapV1_InputCerUsdAmountIsLargerThanMaximumSpecified();
            }

            // amountTokensIn must be larger than 1 to avoid rounding errors
            if (
                amountTokensIn <= 1
            ) {
                revert("U"); // TODO: remove this line on production
                revert CerbySwapV1_AmountOfCerUsdMustBeLargerThanOne();
            }

            // safely transferring tokens from sender to this contract
            // or doing nothing if msg.value specified correctly
            _safeTransferFromHelper(tokenIn, fromAddress, amountTokensIn);

            // swapping cerUSD ---> YYY
            lowLevelSwap(
                tokenOut,
                amountTokensOut,
                0,
                transferTo
            );
        // TODO: uncomment below
        } else if (tokenIn != cerUsdToken && tokenOut != cerUsdToken /*&& tokenIn != tokenOut*/) {

            // getting amountTokensOut
            uint amountCerUsdOut = _getInputCerUsdForExactTokens(tokenOut, amountTokensOut);

            // amountCerUsdOut must be larger than 1 to avoid rounding errors
            if (
                amountCerUsdOut <= 1
            ) {
                revert("U"); // TODO: remove this line on production
                revert CerbySwapV1_AmountOfCerUsdMustBeLargerThanOne();
            }

            amountTokensIn = _getInputTokensForExactCerUsd(tokenIn, amountCerUsdOut);

            // amountTokensIn must be larger than 1 to avoid rounding errors
            if (
                amountTokensIn <= 1
            ) {
                revert("U"); // TODO: remove this line on production
                revert CerbySwapV1_AmountOfCerUsdMustBeLargerThanOne();
            }

            // checking slippage
            if (
                amountTokensIn > maxAmountTokensIn
            ) {
                revert("K"); // TODO: remove this line on production
                revert CerbySwapV1_InputTokensAmountIsLargerThanMaximumSpecified();
            }

            // amountTokensIn must be larger than 1 to avoid rounding errors
            if (
                amountTokensIn <= 1
            ) {
                revert("F"); // TODO: remove this line on production
                revert CerbySwapV1_AmountOfTokensMustBeLargerThanOne();
            }

            // safely transferring tokens from sender to this contract
            // or doing nothing if msg.value specified correctly
            _safeTransferFromHelper(tokenIn, fromAddress, amountTokensIn);
            
            // swapping XXX ---> cerUSD
            lowLevelSwap(
                tokenIn,
                0,
                amountCerUsdOut,
                address(this)
            );

            // swapping cerUSD ---> YYY
            lowLevelSwap(
                tokenOut,
                amountTokensOut,
                0,
                transferTo
            );
        } else {
            revert("L"); // TODO: remove this line on production
            revert CerbySwapV1_SwappingTokenToSameTokenIsForbidden();
        }
        return (amountTokensIn, amountTokensOut);
    }

    function lowLevelSwap(
        address token,
        uint amountTokensOut,
        uint amountCerUsdOut,
        address transferTo
    )
        public
        payable
        tokenMustExistInPool(token)
    {
        Pool storage pool = pools[tokenToPoolId[token]];

        // finding out how many amountCerUsdIn we received
        uint amountCerUsdIn = _getTokenBalance(cerUsdToken) - totalCerUsdBalance;

        // finding out how many amountTokensIn we received
        uint amountTokensIn = _getTokenBalance(token) - pool.balanceToken;
        if (
            amountTokensIn + amountCerUsdIn <= 1
        ) {
            revert("2");
            revert CerbySwapV1_AmountOfCerUsdOrTokensInMustBeLargerThanOne();
        }

        // calculating fees
        // if swap is ANY --> cerUSD, fee is calculated
        // if swap is cerUSD --> ANY, fee is zero
        uint oneMinusFee = 
            amountCerUsdIn > 1 && amountTokensIn <= 1?
                FEE_DENORM:
                _getCurrentOneMinusFeeBasedOnTrades(pool);

        { // scope to avoid stack too deep error

            // checking if cerUsd credit is enough to cover this swap
            if (
                pool.creditCerUsd < type(uint).max &&
                pool.creditCerUsd + amountCerUsdIn < amountCerUsdOut
            ) {
                revert("Z");
                revert CerbySwapV1_CreditCerUsdMustNotBeBelowZero();
            }
            
            // calculating old K value including trade fees (multiplied by FEE_DENORM^2)
            uint beforeKValueDenormed = 
                uint(pool.balanceCerUsd) * FEE_DENORM *
                uint(pool.balanceToken) * FEE_DENORM;

            // calculating new pool values
            uint _totalCerUsdBalance = totalCerUsdBalance + amountCerUsdIn - amountCerUsdOut;
            uint _balanceCerUsd = 
                uint(pool.balanceCerUsd) + amountCerUsdIn - amountCerUsdOut;
            uint _balanceToken =
                uint(pool.balanceToken) + amountTokensIn - amountTokensOut;


            // calculating new K value including trade fees
            uint afterKValueDenormed = 
                (_balanceCerUsd * FEE_DENORM - amountCerUsdIn * (FEE_DENORM - oneMinusFee)) * 
                (_balanceToken * FEE_DENORM - amountTokensIn * (FEE_DENORM - oneMinusFee));
            if (
                afterKValueDenormed < beforeKValueDenormed
            ) {
                revert("1");
                revert CerbySwapV1_InvariantKValueMustBeSameOrIncreasedOnAnySwaps();
            }

            // updating pool values
            totalCerUsdBalance = _totalCerUsdBalance;
            pool.balanceCerUsd = uint128(_balanceCerUsd);
            pool.balanceToken = uint128(_balanceToken);
            
            // updating creditCerUsd only if pool is user-created
            if (pool.creditCerUsd < type(uint).max) {
                pool.creditCerUsd = 
                    pool.creditCerUsd + amountCerUsdIn - amountCerUsdOut;
            }
        }

        // updating 1 hour trade pool values
        // only for direction ANY --> cerUSD
        uint currentPeriod = _getCurrentPeriod();
        uint nextPeriod = (currentPeriod + 1) % NUMBER_OF_TRADE_PERIODS;
        if (amountCerUsdOut > TRADE_VOLUME_DENORM) { // or else amountCerUsdOut / TRADE_VOLUME_DENORM == 0
            // stores in 10xUSD value, up-to $40B per 4 hours per pair will be stored correctly
            uint updatedTradeVolume = 
                uint(pool.tradeVolumePerPeriodInCerUsd[currentPeriod]) + 
                    amountCerUsdOut / TRADE_VOLUME_DENORM; // if ANY --> cerUSD, then output is cerUSD only
            
            // handling overflow just in case
            pool.tradeVolumePerPeriodInCerUsd[currentPeriod] = 
                updatedTradeVolume < type(uint32).max?
                    uint32(updatedTradeVolume):
                    type(uint32).max;
        }

        // clearing next 1 hour trade value
        if (pool.tradeVolumePerPeriodInCerUsd[nextPeriod] > 1)
        {
            // gas saving to not zero the field
            pool.tradeVolumePerPeriodInCerUsd[nextPeriod] = 1;
        }

        // safely transfering tokens
        // and making sure exact amounts were actually transferred
        if (amountTokensOut > 0) {
            _safeTransferHelper(token, transferTo, amountTokensOut, true);
        }

        // safely transfering cerUSD
        // and making sure exact amounts were actually transferred
        if (amountCerUsdOut > 0) {
            _safeTransferHelper(cerUsdToken, transferTo, amountCerUsdOut, true);
        }

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