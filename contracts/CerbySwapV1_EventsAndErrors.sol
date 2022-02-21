// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.12;

abstract contract CerbySwapV1_EventsAndErrors {

    event PoolCreated(
        address _token,
        address _vaultAddress,
        uint256 _poolId
    );

    event LiquidityAdded(
        address _token,
        uint256 _amountTokensIn,
        uint256 _amountCerUsdToMint,
        uint256 _lpAmount
    );
    event LiquidityRemoved(
        address _token,
        uint256 _amountTokensOut,
        uint256 _amountCerUsdToBurn,
        uint256 _amountLpTokensBalanceToBurn
    );
    event Swap(
        address _token,
        address _sender,
        uint256 _amountTokensIn,
        uint256 _amountCerUsdIn,
        uint256 _amountTokensOut,
        uint256 _amountCerUsdOut,
        uint256 _currentFee,
        address _transferTo
    );
    event Sync(
        address _token,
        uint256 _newBalanceToken,
        uint256 _newBalanceCerUsd,
        uint256 _newCreditCerUsd
    );

    error CerbySwapV1_TokenAlreadyExists();
    error CerbySwapV1_TokenDoesNotExist();
    error CerbySwapV1_TransactionIsExpired();
    error CerbySwapV1_AmountOfTokensMustBeLargerThanOne();
    error CerbySwapV1_AmountOfCerUsdMustBeLargerThanOne();
    error CerbySwapV1_OutputCerUsdAmountIsLowerThanMinimumSpecified();
    error CerbySwapV1_OutputTokensAmountIsLowerThanMinimumSpecified();
    error CerbySwapV1_InputCerUsdAmountIsLargerThanMaximumSpecified();
    error CerbySwapV1_InputTokensAmountIsLargerThanMaximumSpecified();
    error CerbySwapV1_SwappingTokenToSameTokenIsForbidden();
    error CerbySwapV1_InvariantKValueMustBeSameOrIncreasedOnAnySwaps();
    error CerbySwapV1_SafeTransferNativeFailed();
    error CerbySwapV1_SafeTransferFromFailed();
    error CerbySwapV1_AmountOfCerUsdOrTokensInMustBeLargerThanOne();
    error CerbySwapV1_FeeIsWrong();
    error CerbySwapV1_TvlMultiplierIsWrong();
    error CerbySwapV1_MintFeeMultiplierMustNotBeLargerThan50Percent();
    error CerbySwapV1_CreditCerUsdMustNotBeBelowZero();
    error CerbySwapV1_CreditCerUsdIsAlreadyMaximum();
}
