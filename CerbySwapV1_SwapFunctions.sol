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
            amountTokensOut = getOutputExactTokensForCerUsd(tokenIn, amountTokensIn);

            // checking slippage
            if (
                amountTokensOut < minAmountTokensOut
            ) {
                revert("H"); // TODO: remove this line on production
                revert CerbySwapV1_OutputCerUsdAmountIsLowerThanMinimumSpecified();
            }

            // actually transferring the tokens to the pool
            _safeTransferFromHelper(tokenIn, fromAddress, amountTokensIn);

            // swapping XXX ---> cerUSD
            _swap(
                tokenIn,
                0,
                amountTokensOut,
                transferTo
            );
        } else if (tokenIn == cerUsdToken && tokenOut != cerUsdToken) {

            // getting amountTokensOut
            amountTokensOut = getOutputExactCerUsdForTokens(tokenOut, amountTokensIn);

            // checking slippage
            if (
                amountTokensOut < minAmountTokensOut
            ) {
                revert("i"); // TODO: remove this line on production
                revert CerbySwapV1_OutputTokensAmountIsLowerThanMinimumSpecified();
            }

            // actually transferring the tokens to the pool
            // for cerUsd don't need to use SafeERC20
            _safeTransferFromHelper(tokenIn, fromAddress, amountTokensIn);

            // swapping cerUSD ---> YYY
            _swap(
                tokenOut,
                amountTokensOut,
                0,
                transferTo
            );
        // TODO: uncomment below
        } else if (tokenIn != cerUsdToken && tokenIn != cerUsdToken /*&& tokenIn != tokenOut*/) {

            // getting amountTokensOut=
            uint amountCerUsdOut = getOutputExactTokensForCerUsd(tokenIn, amountTokensIn);

            amountTokensOut = getOutputExactCerUsdForTokens(tokenOut, amountCerUsdOut);

            // checking slippage
            if (
                amountTokensOut < minAmountTokensOut
            ) {
                revert("i"); // TODO: remove this line on production
                revert CerbySwapV1_OutputTokensAmountIsLowerThanMinimumSpecified();
            }

            // actually transferring the tokens to the pool
            _safeTransferFromHelper(tokenIn, fromAddress, amountTokensIn);

            // swapping XXX ---> cerUSD
            _swap(
                tokenIn,
                0,
                amountCerUsdOut,
                address(this)
            );

            // swapping cerUSD ---> YYY
            _swap(
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
            amountTokensIn = getInputTokensForExactCerUsd(tokenIn, amountTokensOut);

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

            // actually transferring the tokens to the pool
            _safeTransferFromHelper(tokenIn, fromAddress, amountTokensIn);

            // swapping XXX ---> cerUSD
            _swap(
                tokenIn,
                0,
                amountTokensOut,
                transferTo
            );
        } else if (tokenIn == cerUsdToken && tokenOut != cerUsdToken) {

            // getting amountTokensOut
            amountTokensIn = getInputCerUsdForExactTokens(tokenOut, amountTokensOut);

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

            // actually transferring the tokens to the pool
            _safeTransferFromHelper(tokenIn, fromAddress, amountTokensIn);

            // swapping cerUSD ---> YYY
            _swap(
                tokenOut,
                amountTokensOut,
                0,
                transferTo
            );
        // TODO: uncomment below
        } else if (tokenIn != cerUsdToken && tokenOut != cerUsdToken /*&& tokenIn != tokenOut*/) {

            // getting amountTokensOut
            uint amountCerUsdOut = getInputCerUsdForExactTokens(tokenOut, amountTokensOut);
            if (
                amountCerUsdOut <= 1
            ) {
                revert("U"); // TODO: remove this line on production
                revert CerbySwapV1_AmountOfCerUsdMustBeLargerThanOne();
            }

            amountTokensIn = getInputTokensForExactCerUsd(tokenIn, amountCerUsdOut);

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

            // actually transferring the tokens to the pool
            _safeTransferFromHelper(tokenIn, fromAddress, amountTokensIn);
            
            // swapping XXX ---> cerUSD
            _swap(
                tokenIn,
                0,
                amountCerUsdOut,
                address(this)
            );

            // swapping cerUSD ---> YYY
            _swap(
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
    {
        _swap(
            token,
            amountTokensOut,
            amountCerUsdOut,
            transferTo
        );
    }

    function _swap(
        address token,
        uint amountTokensOut,
        uint amountCerUsdOut,
        address transferTo
    )
        private
        tokenMustExistInPool(token)
    {
        uint poolId = tokenToPoolId[token];

        // finding out how many amountCerUsdIn we received
        uint amountCerUsdIn = _getTokenBalance(cerUsdToken) - totalCerUsdBalance;

        // finding out how many amountTokensIn we received
        uint amountTokensIn = _getTokenBalance(token) - pools[poolId].balanceToken;
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
                _getCurrentOneMinusFeeBasedOnTrades(poolId);

        { // scope to avoid stack too deep error

            // checking if cerUsd credit is enough to cover this swap
            if (
                pools[poolId].creditCerUsd < type(uint).max &&
                pools[poolId].creditCerUsd + amountCerUsdIn < amountCerUsdOut
            ) {
                revert("Z");
                revert CerbySwapV1_CreditCerUsdMustNotBeBelowZero();
            }
            
            // calculating old K value including trade fees (multiplied by FEE_DENORM^2)
            uint beforeKValueDenormed = 
                uint(pools[poolId].balanceCerUsd) * FEE_DENORM *
                uint(pools[poolId].balanceToken) * FEE_DENORM;

            // calculating new pool values
            uint _totalCerUsdBalance = totalCerUsdBalance + amountCerUsdIn - amountCerUsdOut;
            uint _balanceCerUsd = 
                uint(pools[poolId].balanceCerUsd) + amountCerUsdIn - amountCerUsdOut;
            uint _balanceToken =
                uint(pools[poolId].balanceToken) + amountTokensIn - amountTokensOut;


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
            pools[poolId].balanceCerUsd = uint128(_balanceCerUsd);
            pools[poolId].balanceToken = uint128(_balanceToken);
            
            // updating creditCerUsd only if pool is user-created
            if (pools[poolId].creditCerUsd < type(uint).max) {
                pools[poolId].creditCerUsd = 
                    pools[poolId].creditCerUsd + amountCerUsdIn - amountCerUsdOut;
            }
        }

        // updating 1 hour trade pool values
        // only for direction ANY --> cerUSD
        uint currentPeriod = getCurrentPeriod();
        uint nextPeriod = (getCurrentPeriod() + 1) % NUMBER_OF_TRADE_PERIODS;
        if (amountCerUsdOut > TRADE_VOLUME_DENORM) { // or else amountCerUsdOut / TRADE_VOLUME_DENORM == 0
            // stores in 10xUSD value, up-to $40B per 4 hours per pair will be stored correctly
            uint updatedTradeVolume = 
                uint(pools[poolId].tradeVolumePerPeriodInCerUsd[currentPeriod]) + 
                    amountCerUsdOut / TRADE_VOLUME_DENORM; // if ANY --> cerUSD, then output is cerUSD only
            
            // handling overflow just in case
            pools[poolId].tradeVolumePerPeriodInCerUsd[currentPeriod] = 
                updatedTradeVolume < type(uint32).max?
                    uint32(updatedTradeVolume):
                    type(uint32).max;
        }

        // clearing next 1 hour trade value
        if (pools[poolId].tradeVolumePerPeriodInCerUsd[nextPeriod] > 1)
        {
            // gas saving to not zero the field
            pools[poolId].tradeVolumePerPeriodInCerUsd[nextPeriod] = 1;
        }

        // transferring tokens from contract to user if any
        if (amountTokensOut > 0) {
            _safeTransferHelper(token, transferTo, amountTokensOut, true);

            // making sure exactly amountTokensOut tokens were sent out
            uint newTokenBalance = _getTokenBalance(token);
            if (
                newTokenBalance != pools[poolId].balanceToken
            ) {
                revert CerbySwapV1_FeeOnTransferTokensArentSupported();
            }
        }

        // transferring cerUsd tokens to user if any
        if (amountCerUsdOut > 0) {
            _safeTransferHelper(cerUsdToken, transferTo, amountCerUsdOut, true);
        }     

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

        emit Sync(
            token, 
            pools[poolId].balanceToken, 
            pools[poolId].balanceCerUsd,
            pools[poolId].creditCerUsd
        );
    }
}