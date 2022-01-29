// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.11;


abstract contract CerbySwapV1_EventsAndErrors {

    event PairCreated(
        address token,
        uint poolId
    );
    event LiquidityAdded(
        address token, 
        uint amountTokensIn, 
        uint amountCerUsdToMint, 
        uint lpAmount
    );
    event LiquidityRemoved(
        address token, 
        uint amountTokensOut, 
        uint amountCerUsdToBurn, 
        uint amountLpTokensBalanceToBurn
    );
    event Swap(
        address token,
        address sender, 
        uint amountTokensIn, 
        uint amountCerUsdIn, 
        uint amountTokensOut, 
        uint amountCerUsdOut,
        uint currentFee,
        address transferTo
    );
    event Sync(
        address token, 
        uint newBalanceToken, 
        uint newBalanceCerUsd,
        uint newCreditCerUsd
    );

        
    error CerbySwapV1_TokenAlreadyExists();
    error CerbySwapV1_TokenDoesNotExist();
    error CerbySwapV1_TransactionIsExpired();
    error CerbySwapV1_FeeOnTransferTokensArentSupported();
    error CerbySwapV1_AmountOfTokensMustBeLargerThanOne();
    error CerbySwapV1_AmountOfCerUsdMustBeLargerThanOne();
    error CerbySwapV1_MsgValueProvidedMustBeZero();
    error CerbySwapV1_OutputCerUsdAmountIsLowerThanMinimumSpecified();
    error CerbySwapV1_OutputTokensAmountIsLowerThanMinimumSpecified();
    error CerbySwapV1_InputCerUsdAmountIsLargerThanMaximumSpecified();
    error CerbySwapV1_InputTokensAmountIsLargerThanMaximumSpecified();
    error CerbySwapV1_SwappingTokenToSameTokenIsForbidden();
    error CerbySwapV1_InvariantKValueMustBeSameOrIncreasedOnAnySwaps();
    error CerbySwapV1_SafeTransferNativeFailed();
    error CerbySwapV1_SafeTransferTokensFailed();
    error CerbySwapV1_SafeTransferFromFailed();
    error CerbySwapV1_MsgValueProvidedMustBeLargerThanAmountIn();
    error CerbySwapV1_AmountOfCerUsdOrTokensInMustBeLargerThanOne();
    error CerbySwapV1_FeeIsWrong();
    error CerbySwapV1_TvlMultiplierIsWrong();
    error CerbySwapV1_MintFeeMultiplierMustNotBeLargerThan50Percent();
    error CerbySwapV1_CreditCerUsdIsOverflown();
    error CerbySwapV1_CreditCerUsdMustNotBeBelowZero();
}