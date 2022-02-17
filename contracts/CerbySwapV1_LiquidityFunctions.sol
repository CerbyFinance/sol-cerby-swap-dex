// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.12;

import "./CerbySwapV1_GetFunctions.sol";
import "./CerbySwapV1_Modifiers.sol";
import "./CerbySwapV1_Math.sol";
import "./CerbySwapV1_ERC1155.sol";
import "./CerbySwapV1_MinimalProxy.sol";
import "./interfaces/ICerbyTokenMinterBurner.sol";

abstract contract CerbySwapV1_LiquidityFunctions is
    CerbySwapV1_Modifiers,
    CerbySwapV1_Math,
    CerbySwapV1_ERC1155,
    CerbySwapV1_GetFunctions
{
    // user can increase cerUsd credit in the pool
    function increaseCerUsdCreditInPool(
        address _token,
        uint256 _amountCerUsdCredit
    )
        external
    {
        // getting pool storage link (saves gas compared to memory)
        Pool storage pool = pools[cachedTokenValues[_token].poolId];

        // if the pool is official, we don't increase credit
        if (pool.creditCerUsd == MAX_CER_USD_CREDIT) {
            revert CerbySwapV1_CreditCerUsdIsAlreadyMaximum();
        }

        // increasing credit for user-created pool
        pool.creditCerUsd += uint120(
            _amountCerUsdCredit
        );

        // burning user's cerUsd tokens in order to increase the credit for given pool
        ICerbyTokenMinterBurner(CER_USD_TOKEN).burnHumanAddress(
            msg.sender,
            _amountCerUsdCredit
        );

        // Sync event to update pool variables in the graph node
        PoolBalances memory poolBalances = _getPoolBalances(
            _token
        );
        emit Sync(
            _token,
            poolBalances.balanceToken,
            poolBalances.balanceCerUsd,
            pool.creditCerUsd
        );
    }

    // users are allowed to create new pools but only with creditCerUsd = 0
    function createPool( // C: never tested (this seems critical to test user actions)
        address _token,
        uint256 _amountTokensIn,
        uint256 _amountCerUsdToMint,
        address _transferTo
    )
        external
        payable
    {
        _createPool(
            _token,
            _amountTokensIn,
            _amountCerUsdToMint,
            0, // creditCerUsd
            _transferTo
        );
    }

    function _createPool(
        address _token,
        uint256 _amountTokensIn,
        uint256 _amountCerUsdToMint,
        uint256 _creditCerUsd,
        address _transferTo
    )
        internal
    {
        if (cachedTokenValues[_token].poolId > 0) {
            revert ("saddsasadsdaasd");
            revert CerbySwapV1_TokenAlreadyExists();
        }

        // creating vault contract to safely store tokens
        address vaultAddress = cloneVault(
            _token
        );

        ICerbySwapV1_Vault(vaultAddress).initialize(
            _token
        );

        // safely transferring tokens from sender to the vault
        _safeTransferFromHelper(
            _token,
            msg.sender,
            vaultAddress,
            _amountTokensIn
        );

        // minting requested amount of cerUSD tokens to this contract
        ICerbyTokenMinterBurner(CER_USD_TOKEN).mintHumanAddress(
            vaultAddress,
            _amountCerUsdToMint
        );

        // finding out how many tokens received
        _amountTokensIn = _getTokenBalance(
            _token,
            vaultAddress
        );

        if (_amountTokensIn <= 1) {
            revert("F"); // TODO: remove this line on production // C: concern
            revert CerbySwapV1_AmountOfTokensMustBeLargerThanOne();
        }

        // preparing pool object to push into storage
        // filling trade volume with 1 (gas savings in runtime)
        uint40[NUMBER_OF_TRADE_PERIODS] memory tradeVolumePerPeriodInCerUsd;

        for (uint256 i; i < NUMBER_OF_TRADE_PERIODS; i++) {
            tradeVolumePerPeriodInCerUsd[i] = 1;
        }

        uint256 newSqrtKValue = sqrt(
            _amountTokensIn * _amountCerUsdToMint
        );

        Pool memory pool = Pool({
            tradeVolumePerPeriodInCerUsd: tradeVolumePerPeriodInCerUsd,
            lastCachedOneMinusFee: uint16(FEE_DENORM - settings.feeMaximum),
            lastCachedTradePeriod: uint8(_getCurrentPeriod()),
            lastSqrtKValue: uint120(newSqrtKValue),
            creditCerUsd: uint120(_creditCerUsd)
        });

        // remembering the position where new pool will be pushed to
        uint256 poolId = pools.length;
        pools.push(pool);

        // remembering poolId in the mapping
        cachedTokenValues[_token].poolId = uint96(poolId);

        // minting 1000 lp tokens to null address as per uniswap v2 whitepaper
        // refer to 3.4 Initialization of liquidity token supply https://uniswap.org/whitepaper.pdf
        _mint(
            DEAD_ADDRESS,
            poolId,
            MINIMUM_LIQUIDITY
        );

        // minting initial lp tokens
        uint256 lpAmount = newSqrtKValue
            - MINIMUM_LIQUIDITY;

        _mint(
            _transferTo,
            poolId,
            lpAmount
        );

        // PoolCreated event is needed to track new pairs created in the graph node
        emit PoolCreated(
            _token,
            vaultAddress,
            poolId
        );

        // LiquidityAdded event is needed to post in telegram channel
        emit LiquidityAdded(
            _token,
            _amountTokensIn,
            _amountCerUsdToMint,
            lpAmount
        );

        // Sync event to update pool variables in the graph node
        emit Sync(
            _token,
            _amountTokensIn,
            _amountCerUsdToMint,
            _creditCerUsd
        );
    }

    function addTokenLiquidity(
        address _token,
        uint256 _amountTokensIn,
        uint256 _expireTimestamp,
        address _transferTo
    )
        external
        payable
        tokenMustExistInPool(_token)
        transactionIsNotExpired(_expireTimestamp)
        // checkForBots(msg.sender) // TODO: enable on production // C: concern
        returns (uint256)
    {
        // getting pool storage link (saves gas compared to memory)
        uint256 poolId = cachedTokenValues[_token].poolId;
        Pool storage pool = pools[poolId];

        address vaultInAddress = _getCachedVaultCloneAddressByToken(
            _token
        );

        // remembering balance before the transfer
        PoolBalances memory poolBalancesBefore = _getPoolBalances(
            _token
        );

        // safely transferring tokens from sender to the vault
        _safeTransferFromHelper(
            _token,
            msg.sender,
            vaultInAddress,
            _amountTokensIn
        );

        // remembering balance after the transfer
        uint256 tokenBalanceAfter = _getTokenBalance(
            _token,
            vaultInAddress
        );

        // finding out how many tokens we've actually received
        _amountTokensIn = tokenBalanceAfter
            - poolBalancesBefore.balanceToken;

        if (_amountTokensIn <= 1) {
            revert("F"); // TODO: remove this line on production
            revert CerbySwapV1_AmountOfTokensMustBeLargerThanOne();
        }

        // calculating protocol trade fees
        uint256 amountLpTokensToMintAsFee = _getMintFeeLiquidityAmount(
            uint256(pool.lastSqrtKValue),
            // calculating sqrt(k) value before pool balances are updated
            sqrt(poolBalancesBefore.balanceToken * poolBalancesBefore.balanceCerUsd),
            contractTotalSupply[poolId]
        );

        // minting protocol trade fees
        _mint(
            settings.mintFeeBeneficiary,
            poolId,
            amountLpTokensToMintAsFee
        );

        // calculating amount of cerUSD to mint according to current price
        uint256 amountCerUsdToMint = _amountTokensIn
            * poolBalancesBefore.balanceCerUsd
            / poolBalancesBefore.balanceToken;

        if (amountCerUsdToMint <= 1) {
            revert CerbySwapV1_AmountOfCerUsdMustBeLargerThanOne();
        }

        // updating pool variables
        pool.lastSqrtKValue = uint120(
            sqrt(
                tokenBalanceAfter 
                * (poolBalancesBefore.balanceCerUsd + amountCerUsdToMint) // cerUSD balance has increased by amountCerUsdToMint
            )
        );

        // minting cerUSD according to current pool
        ICerbyTokenMinterBurner(CER_USD_TOKEN).mintHumanAddress(
            vaultInAddress,
            amountCerUsdToMint
        );

        // calculating LP tokens
        uint256 lpAmount = _amountTokensIn
            * contractTotalSupply[poolId] // contractTotalSupply[poolId] might have changed during mintFee, we are using updated value
            / poolBalancesBefore.balanceToken;

        // minting LP tokens (subject to re-entrancty attack, doing it last)
        _mint(
            _transferTo,
            poolId,
            lpAmount
        );

        // LiquidityAdded event is needed to post in telegram channel
        emit LiquidityAdded(
            _token,
            _amountTokensIn,
            amountCerUsdToMint,
            lpAmount
        );

        // Sync event to update pool variables in the graph node
        emit Sync(
            _token,
            tokenBalanceAfter,
            poolBalancesBefore.balanceCerUsd + amountCerUsdToMint, // cerUSD balance has increased by amountCerUsdToMint
            pool.creditCerUsd
        );

        return lpAmount;
    }

    function removeTokenLiquidity(
        address _token,
        uint256 _amountLpTokensBalanceToBurn,
        uint256 _expireTimestamp,
        address _transferTo
    )
        external
        tokenMustExistInPool(_token)
        transactionIsNotExpired(_expireTimestamp)
        // checkForBots(msg.sender) // TODO: enable on production
        returns (uint256)
    {
        // to avoid stack too deep error using private function here
        return _removeTokenLiquidity(
            _token,
            _amountLpTokensBalanceToBurn,
            _transferTo
        );
    }

    function _removeTokenLiquidity(
        address _token,
        uint256 _amountLpTokensBalanceToBurn,
        address _transferTo
    )
        private
        returns (uint256)
    {
        // getting pool storage link (saves gas compared to memory)
        uint256 poolId = cachedTokenValues[_token].poolId;
        Pool storage pool = pools[poolId];

        PoolBalances memory poolBalancesBefore = _getPoolBalances(
            _token
        );

        // minting trade fees
        uint256 amountLpTokensToMintAsFee = _getMintFeeLiquidityAmount(
            uint256(pool.lastSqrtKValue),
            // calculating sqrt(k) value before pool balances are updated
            sqrt(poolBalancesBefore.balanceToken * poolBalancesBefore.balanceCerUsd),
            contractTotalSupply[poolId]
        );

        _mint(
            settings.mintFeeBeneficiary,
            poolId,
            amountLpTokensToMintAsFee
        );

        // calculating amount of tokens to transfer
        uint256 amountTokensOut = poolBalancesBefore.balanceToken
            * _amountLpTokensBalanceToBurn
            / contractTotalSupply[poolId]; // contractTotalSupply[poolId] might have changed during mintFee, we are using updated value

        // calculating amount of cerUSD to burn
        uint256 amountCerUsdToBurn = poolBalancesBefore.balanceCerUsd
            * _amountLpTokensBalanceToBurn
            / contractTotalSupply[poolId]; // contractTotalSupply[poolId] might have changed during mintFee, we are using updated value

        // updating pool variables
        PoolBalances memory poolBalancesAfter = PoolBalances(
            poolBalancesBefore.balanceToken - amountTokensOut,
            poolBalancesBefore.balanceCerUsd - amountCerUsdToBurn
        );

        pool.lastSqrtKValue = uint120(
            sqrt(poolBalancesAfter.balanceToken * poolBalancesAfter.balanceCerUsd)
        );

        // burning LP tokens from sender (without approval)
        _burn(
            msg.sender,
            poolId,
            _amountLpTokensBalanceToBurn
        );

        // burning cerUSD
        address vaultOutAddress = _getCachedVaultCloneAddressByToken(
            _token
        );

        ICerbyTokenMinterBurner(CER_USD_TOKEN).burnHumanAddress(
            vaultOutAddress,
            amountCerUsdToBurn
        );

        // safely transfering tokens
        // and making sure exact amounts were actually transferred
        _safeTransferFromHelper(
            _token,
            vaultOutAddress,
            _transferTo,
            amountTokensOut
        );

        // LiquidityRemoved event is needed to post in telegram channel
        emit LiquidityRemoved(
            _token,
            amountTokensOut,
            amountCerUsdToBurn,
            _amountLpTokensBalanceToBurn
        );

        // Sync event to update pool variables in the graph node
        emit Sync(
            _token,
            poolBalancesAfter.balanceToken,
            poolBalancesAfter.balanceCerUsd,
            pool.creditCerUsd
        );

        return amountTokensOut;
    }

    function _getMintFeeLiquidityAmount(
        uint256 _oldSqrtKValue,
        uint256 _newSqrtKValue,
        uint256 _totalLPSupply
    )
        private
        view
        returns (uint256)
    {
        uint256 mintFeePercentage = uint256(
            settings.mintFeeMultiplier
        );

        if (
            mintFeePercentage == 0 || // mint fee is disabled
            _newSqrtKValue <= _oldSqrtKValue // K value has decreased or unchanged
        ) {
            return 0;
        }

        // mint fee is enabled && K value increased
        // refer to 2.4 Protocol fee https://uniswap.org/whitepaper.pdf
        return _totalLPSupply
            * mintFeePercentage
            * (_newSqrtKValue - _oldSqrtKValue)
            / (
                _newSqrtKValue
                * (MINT_FEE_DENORM - mintFeePercentage)
                    + _oldSqrtKValue * mintFeePercentage
            );
    }
}
