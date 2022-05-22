// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.14;

import "./CerbySwapV1_GetFunctions.sol";
import "./CerbySwapV1_Modifiers.sol";
import "./CerbySwapV1_Math.sol";
import "./CerbySwapV1_ERC1155.sol";
import "./CerbySwapV1_MinimalProxy.sol";

abstract contract CerbySwapV1_LiquidityFunctions is
    CerbySwapV1_Modifiers,
    CerbySwapV1_Math,
    CerbySwapV1_ERC1155,
    CerbySwapV1_GetFunctions
{
    // user can increase CERBY credit in the pool
    function increaseCerbyCreditInPool(
        ICerbyERC20 _token,
        uint256 _amountCerbyCredit
    )
        external
    {
        // getting pool storage link (saves gas compared to memory)
        Pool storage pool = pools[cachedTokenValues[_token].poolId];

        // if the pool is official, we don't increase credit
        if (pool.creditCerby == MAX_CERBY_CREDIT) {
            revert CerbySwapV1_CreditCerbyIsAlreadyMaximum();
        }

        // increasing credit for user-created pool
        pool.creditCerby += uint128(
            _amountCerbyCredit
        );

        // burning user's CERBY tokens in order to increase the credit for given pool
        CERBY_TOKEN.burnHumanAddress(
            msg.sender,
            _amountCerbyCredit
        );

        // Sync event to update pool variables in the graph node
        PoolBalances memory poolBalances = _getPoolBalances(
            _token
        );
        emit Sync(
            _token,
            poolBalances.balanceToken,
            poolBalances.balanceCerby,
            pool.creditCerby
        );
    }

    // users are allowed to create new pools but only with creditCerby = 0
    function createPool(
        ICerbyERC20 _token,
        uint256 _amountTokensIn,
        uint256 _amountCerbyToMint,
        address _transferTo
    )
        external
        payable
    {
        _createPool(
            _token,
            _amountTokensIn,
            _amountCerbyToMint,
            0, // creditCerby
            _transferTo
        );
    }

    function _createPool(
        ICerbyERC20 _token,
        uint256 _amountTokensIn,
        uint256 _amountCerbyToMint,
        uint256 _creditCerby,
        address _transferTo
    )
        internal
    {
        if (cachedTokenValues[_token].poolId > 0) {
            revert ("saddsasadsdaasd");
            revert CerbySwapV1_TokenAlreadyExists();
        }

        if (_amountTokensIn <= 1) {
            revert("F"); // TODO: remove this line on production
            revert CerbySwapV1_AmountOfTokensMustBeLargerThanOne();
        }

        // for native token we use current contract as a vault
        ICerbySwapV1_Vault vaultAddress = ICerbySwapV1_Vault(address(this));

        if (NATIVE_TOKEN != _token) {
            // creating vault contract to safely store tokens
            vaultAddress = _cloneVault(
                _token
            );

            vaultAddress.initialize(
                _token
            );
        }

        // non-official pools require forbidding basic fee-on-transfer tokens
        // however it is not a big deal if someone bypasses it
        // due to credit system they won't be allowed to withdraw more CERBY than deposited
        if (_creditCerby != MAX_CERBY_CREDIT) {
            // remembering balance before the transfer
            uint256 balanceBefore = _getTokenBalance(_token, vaultAddress);

            // safely transferring tokens from sender to the vault
            _safeTransferFromHelper(
                _token,
                msg.sender,
                address(vaultAddress),
                _amountTokensIn
            );

            // remembering balance after the transfer
            uint256 balanceAfter = _getTokenBalance(_token, vaultAddress);

            // making sure to forbid fee on transfer tokens on pool creation
            // that means assuming anywhere else token is standard non fee-on-transfer
            // _amountTokensIn is exactly how many tokens were transferred to vaultAddress
            if (balanceAfter != balanceBefore + _amountTokensIn) {
                revert CerbySwapV1_FeeOnTransferTokensAreForbidden();
            }

            // usually balanceBefore must be zero
            // if for some reason vault had tokens in the contract
            // we consider user sent them and adding to his initial amount
            _amountTokensIn += balanceBefore;
        } else {

            // safely transferring tokens from sender to the vault
            // without extra checks
            _safeTransferFromHelper(
                _token,
                msg.sender,
                address(vaultAddress),
                _amountTokensIn
            );
        }

        // minting requested amount of CERBY tokens to vaultAddress
        CERBY_TOKEN.mintHumanAddress(
            address(vaultAddress),
            _amountCerbyToMint
        );


        uint256 newSqrtKValue = sqrt(
            _amountTokensIn * _amountCerbyToMint
        );

        Pool memory pool = Pool({
            sellVolumeThisPeriodInCerby: 0,
            lastCachedFee: uint8(settings.feeMaximum),
            nextUpdateWillBeAt: uint32(block.timestamp) + settings.onePeriodInSeconds,
            lastSqrtKValue: uint128(newSqrtKValue),
            creditCerby: uint128(_creditCerby)
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
        uint256 lpAmount = newSqrtKValue - MINIMUM_LIQUIDITY;

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
            _amountCerbyToMint,
            lpAmount
        );

        // Sync event to update pool variables in the graph node
        emit Sync(
            _token,
            _amountTokensIn,
            _amountCerbyToMint,
            _creditCerby
        );
    }

    function addTokenLiquidity(
        ICerbyERC20 _token,
        uint256 _amountTokensIn,
        uint256 _expireTimestamp,
        address _transferTo
    )
        external
        payable
        tokenMustExistInPool(_token)
        transactionIsNotExpired(_expireTimestamp)
        // checkForBots(msg.sender) // TODO: enable on production
        returns (uint256)
    {
        if (_amountTokensIn <= 1) {
            revert("F"); // TODO: remove this line on production
            revert CerbySwapV1_AmountOfTokensMustBeLargerThanOne();
        }

        // getting pool storage link (saves gas compared to memory)
        uint256 poolId = cachedTokenValues[_token].poolId;
        Pool storage pool = pools[poolId];

        ICerbySwapV1_Vault vaultInAddress = _getVaultAddress(_token);

        // remembering balance before the transfer
        PoolBalances memory poolBalancesBefore = _getPoolBalances(
            _token
        );

        // because native token is already sent to the contract during the call
        // we need to substract msg.value in order to know balance before the transfer
        if (NATIVE_TOKEN == _token) {
            poolBalancesBefore.balanceToken -= msg.value;
        }

        // safely transferring tokens from sender to the vault
        // assuming that _amountTokensIn is exact amount transferred
        // because we forbid fee on transfer tokens on pool creation
        _safeTransferFromHelper(
            _token,
            msg.sender,
            address(vaultInAddress),
            _amountTokensIn
        );

        // calculating trade fees
        uint256 amountLpTokensToMintAsFee = _getMintFeeLiquidityAmount(
            uint256(pool.lastSqrtKValue),
            // calculating sqrt(k) value before pool balances are updated
            sqrt(poolBalancesBefore.balanceToken * poolBalancesBefore.balanceCerby),
            erc1155TotalSupply[poolId]
        );

        // minting protocol fees
        _mint(
            settings.mintFeeBeneficiary,
            poolId,
            amountLpTokensToMintAsFee
        );

        // calculating amount of CERBY to mint according to current price
        uint256 amountCerbyToMint = _amountTokensIn * poolBalancesBefore.balanceCerby / 
            poolBalancesBefore.balanceToken;

        if (amountCerbyToMint <= 1) {
            revert CerbySwapV1_AmountOfCerbyMustBeLargerThanOne();
        }

        // updating pool variables
        PoolBalances memory poolBalancesAfter = PoolBalances({
            balanceToken: poolBalancesBefore.balanceToken + _amountTokensIn,
            balanceCerby: poolBalancesBefore.balanceCerby + amountCerbyToMint
        });
        pool.lastSqrtKValue = uint128(
            sqrt(
                poolBalancesAfter.balanceToken * poolBalancesAfter.balanceCerby
            )
        );

        // minting CERBY according to current pool
        CERBY_TOKEN.mintHumanAddress(
            address(vaultInAddress),
            amountCerbyToMint
        );

        // calculating LP tokens
        // erc1155TotalSupply[poolId] might have changed during mintFee, we are using updated value, refer to line 143 https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Pair.sol
        uint256 lpAmount = _amountTokensIn * erc1155TotalSupply[poolId] / 
            poolBalancesBefore.balanceToken;

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
            amountCerbyToMint,
            lpAmount
        );

        // Sync event to update pool variables in the graph node
        emit Sync(
            _token,
            poolBalancesAfter.balanceToken,
            poolBalancesAfter.balanceCerby,
            pool.creditCerby
        );

        return lpAmount;
    }

    function removeTokenLiquidity(
        ICerbyERC20 _token,
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
        ICerbyERC20 _token,
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

        // calculating protocol fees
        uint256 amountLpTokensToMintAsFee = _getMintFeeLiquidityAmount(
            uint256(pool.lastSqrtKValue),
            // calculating sqrt(k) value before pool balances are updated
            sqrt(poolBalancesBefore.balanceToken * poolBalancesBefore.balanceCerby),
            erc1155TotalSupply[poolId]
        );

        // minting protocol fees
        _mint(
            settings.mintFeeBeneficiary,
            poolId,
            amountLpTokensToMintAsFee
        );

        // calculating amount of tokens to transfer
        uint256 amountTokensOut = poolBalancesBefore.balanceToken * _amountLpTokensBalanceToBurn / 
            erc1155TotalSupply[poolId]; // erc1155TotalSupply[poolId] might have changed during mintFee, we are using updated value, refer to line 143 https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Pair.sol

        // calculating amount of CERBY to burn
        uint256 amountCerbyToBurn = poolBalancesBefore.balanceCerby * _amountLpTokensBalanceToBurn /
            erc1155TotalSupply[poolId]; // erc1155TotalSupply[poolId] might have changed during mintFee, we are using updated value, refer to line 143 https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Pair.sol

        // updating pool variables
        PoolBalances memory poolBalancesAfter = PoolBalances({
            balanceToken: poolBalancesBefore.balanceToken - amountTokensOut,
            balanceCerby: poolBalancesBefore.balanceCerby - amountCerbyToBurn
        });
        pool.lastSqrtKValue = uint128(
            sqrt(poolBalancesAfter.balanceToken * poolBalancesAfter.balanceCerby)
        );

        // burning LP tokens from sender (without approval)
        _burn(
            msg.sender,
            poolId,
            _amountLpTokensBalanceToBurn
        );

        // burning CERBY
        ICerbySwapV1_Vault vaultOutAddress = _getVaultAddress(_token);

        CERBY_TOKEN.burnHumanAddress(
            address(vaultOutAddress),
            amountCerbyToBurn
        );

        // safely transfering tokens
        // and making sure exact amounts were actually transferred
        _safeTransferFromHelper(
            _token,
            address(vaultOutAddress),
            _transferTo,
            amountTokensOut
        );

        // LiquidityRemoved event is needed to post in telegram channel
        emit LiquidityRemoved(
            _token,
            amountTokensOut,
            amountCerbyToBurn,
            _amountLpTokensBalanceToBurn
        );

        // Sync event to update pool variables in the graph node
        emit Sync(
            _token,
            poolBalancesAfter.balanceToken,
            poolBalancesAfter.balanceCerby,
            pool.creditCerby
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
        return _totalLPSupply * mintFeePercentage * (_newSqrtKValue - _oldSqrtKValue) /
            (
                _newSqrtKValue * (MINT_FEE_DENORM - mintFeePercentage) +
                    _oldSqrtKValue * mintFeePercentage
            );
    }
}
