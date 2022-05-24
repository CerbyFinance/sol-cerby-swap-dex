// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.14;

import "./interfaces/ICerbyERC20.sol";
import "./interfaces/ICerbySwapV1_Vault.sol";

abstract contract CerbySwapV1_Declarations {

    Pool[] pools;

    mapping(ICerbyERC20 => TokenCache) cachedTokenValues;
    
    ICerbyERC20 constant CERBY_TOKEN = ICerbyERC20(0xE7126C0Fb4B1f5F79E5Bbec3948139dCF348B49C);
    ICerbySwapV1_Vault constant VAULT_IMPLEMENTATION = 
        ICerbySwapV1_Vault(0x029581a9121998fcBb096ceafA92E3E10057878f);
    ICerbyERC20 constant NATIVE_TOKEN = ICerbyERC20(0x14769F96e57B80c66837701DE0B43686Fb4632De);


    // address constant NATIVE_TOKEN = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // Ethereum
    // address constant NATIVE_TOKEN = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // BSC
    // address constant NATIVE_TOKEN = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; // Polygon
    // address constant NATIVE_TOKEN = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7; // Avalanche
    // address constant NATIVE_TOKEN = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83; // Fantom

    uint256 constant MINT_FEE_DENORM = 10_000;
    uint256 constant MAX_CERBY_CREDIT = type(uint128).max;

    uint256 constant FEE_DENORM = 10_000;
    uint256 constant FEE_DENORM_SQUARED = FEE_DENORM * FEE_DENORM;

    uint256 constant TVL_MULTIPLIER_DENORM = 1e10;

    uint256 constant MINIMUM_LIQUIDITY = 1_000;
    address constant DEAD_ADDRESS = address(0xdead);

    Settings settings;

    struct TokenCache {
        ICerbySwapV1_Vault vaultAddress;
        uint96 poolId;
    }

    struct Settings {
        uint32 onePeriodInSeconds;
        address mintFeeBeneficiary;
        uint32 mintFeeMultiplier;
        uint8 feeMinimum;
        uint8 feeMaximum;
        uint64 tvlMultiplierMinimum;
        uint64 tvlMultiplierMaximum;
    }

    struct Pool {
        uint128 sellVolumeThisPeriodInCerby;
        uint8 lastCachedFee;
        uint32 nextUpdateWillBeAt;
        uint128 lastSqrtKValue; // almost impossible to overflow: sqrt(balanceToken * balanceCerby) <= (balanceToken + balanceCerby) / 2
        uint128 creditCerby;
    }

    struct PoolBalances {
        uint256 balanceToken;
        uint256 balanceCerby;
    }


    event PoolCreated(
        ICerbyERC20 indexed _token,
        ICerbySwapV1_Vault _vaultAddress,
        uint256 _poolId
    );

    event LiquidityAdded(
        ICerbyERC20 indexed _token,
        uint256 _amountTokensIn,
        uint256 _amountCerbyToMint,
        uint256 _lpAmount
    );
    event LiquidityRemoved(
        ICerbyERC20 indexed _token,
        uint256 _amountTokensOut,
        uint256 _amountCerbyToBurn,
        uint256 _amountLpTokensBalanceToBurn
    );
    event Swap(
        ICerbyERC20 indexed _token,
        address _sender,
        uint256 _amountTokensIn,
        uint256 _amountCerbyIn,
        uint256 _amountTokensOut,
        uint256 _amountCerbyOut,
        uint256 _currentFee,
        address _transferTo
    );
    event Sync(
        ICerbyERC20 indexed _token,
        uint256 _newBalanceToken,
        uint256 _newBalanceCerby,
        uint256 _newCreditCerby
    );

    error CerbySwapV1_TokenAlreadyExists();
    error CerbySwapV1_TokenDoesNotExist();
    error CerbySwapV1_TransactionIsExpired();
    error CerbySwapV1_AmountOfTokensMustBeLargerThanOne();
    error CerbySwapV1_AmountOfCerbyMustBeLargerThanOne();
    error CerbySwapV1_OutputCerbyAmountIsLowerThanMinimumSpecified();
    error CerbySwapV1_OutputTokensAmountIsLowerThanMinimumSpecified();
    error CerbySwapV1_InputCerbyAmountIsLargerThanMaximumSpecified();
    error CerbySwapV1_InputTokensAmountIsLargerThanMaximumSpecified();
    error CerbySwapV1_SwappingTokenToSameTokenIsForbidden();
    error CerbySwapV1_InvariantKValueMustBeSameOrIncreasedOnAnySwaps();
    error CerbySwapV1_SafeTransferNativeFailed();
    error CerbySwapV1_SafeTransferFromFailed();
    error CerbySwapV1_AmountOfCerbyOrTokensInMustBeLargerThanOne();
    error CerbySwapV1_FeeIsWrong();
    error CerbySwapV1_TvlMultiplierIsWrong();
    error CerbySwapV1_MintFeeMultiplierMustNotBeLargerThan50Percent();
    error CerbySwapV1_CreditCerbyMustNotBeBelowZero();
    error CerbySwapV1_CreditCerbyIsAlreadyMaximum();
    error CerbySwapV1_FeeOnTransferTokensAreForbidden();
    error CerbySwapV1_MsgValueMustBeLargerOrEqualToAmountTokensIn();
    error CerbySwapV1_MsgValueMustBeZeroForNonNativeTokenSwaps();
    error CerbySwapV1_MsgValueMustBeZeroForRemovingLiquidity();
}
