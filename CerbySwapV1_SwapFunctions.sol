// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.11;

import "./CerbySwapV1_GetFunctions.sol";
import "./CerbySwapV1_Modifiers.sol";
import "./CerbySwapV1_Math.sol";
import "./CerbySwapV1_ERC1155.sol";
import "./CerbySwapV1_Vault.sol";
import "./interfaces/ICerbyTokenMinterBurner.sol";

abstract contract CerbySwapV1_SwapFunctions is
    CerbySwapV1_Modifiers,
    CerbySwapV1_Math,
    CerbySwapV1_ERC1155,
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
        public
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

        // calculating old K value including trade fees (multiplied by FEE_DENORM^2)
        uint256 beforeKValueDenormed = _poolBalancesBefore.balanceToken *
            _poolBalancesBefore.balanceCerUsd *
            FEE_DENORM_SQUARED;

        // calculating fees
        // if swap is ANY --> cerUSD, fee is calculated
        // if swap is cerUSD --> ANY, fee is zero
        uint256 oneMinusFee = amountCerUsdIn > 1 && amountTokensIn <= 1
            ? FEE_DENORM
            : _getCurrentOneMinusFeeBasedOnTrades(_token, _poolBalancesBefore);
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
            if (afterKValueDenormed < beforeKValueDenormed) {
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
                    _getCurrentPeriod()
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

    // ---------------------------------------------- //
    // ---------------------------------------------- //
    // ---------------------------------------------- //

    // user can increase cerUsd credit in the pool
    function increaseCerUsdCreditInPool(
        address _token,
        uint256 _amountCerUsdCredit
    ) public {
        // getting pool storage link (saves gas compared to memory)
        Pool storage pool = pools[tokenToPoolId[_token]];

        PoolBalances memory poolBalances = _getPoolBalances(
            _token,
            pool.vaultAddress
        );

        if (pool.creditCerUsd < MAX_CER_USD_CREDIT) {
            // increasing credit for user-created pool
            pool.creditCerUsd += uint128(_amountCerUsdCredit);

            // burning user's cerUsd tokens in order to increase the credit for given pool
            ICerbyTokenMinterBurner(cerUsdToken).burnHumanAddress(
                msg.sender,
                _amountCerUsdCredit
            );
        }

        // Sync event to update pool variables in the graph node
        emit Sync(
            _token,
            poolBalances.balanceToken,
            poolBalances.balanceCerUsd,
            pool.creditCerUsd
        );
    }

    // only users are allowed to create new pools with creditCerUsd = 0
    function createPool(
        address _token,
        uint256 _amountTokensIn,
        uint256 _amountCerUsdToMint,
        address _transferTo
    ) public payable {
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
    ) internal tokenDoesNotExistInPool(_token) {
        // creating vault contract to safely store tokens
        address vaultAddress = address(
            // TODO: remove cerUsdToken from parameters on production
            new CerbySwapV1_Vault(_token, cerUsdToken, _token == nativeToken)
        );

        // safely transferring tokens from sender to the vault
        _safeTransferFromHelper(
            _token,
            msg.sender,
            vaultAddress,
            _amountTokensIn
        );

        // minting requested amount of cerUSD tokens to this contract
        ICerbyTokenMinterBurner(cerUsdToken).mintHumanAddress(
            vaultAddress,
            _amountCerUsdToMint
        );

        // finding out how many tokens received
        _amountTokensIn = _getTokenBalance(_token, vaultAddress);
        if (_amountTokensIn <= 1) {
            revert("F"); // TODO: remove this line on production
            revert CerbySwapV1_AmountOfTokensMustBeLargerThanOne();
        }

        // create new pool record
        uint256 newSqrtKValue = sqrt(_amountTokensIn * _amountCerUsdToMint);

        // preparing pool object to push into storage
        Pool memory pool = Pool(
            vaultAddress,
            uint128(newSqrtKValue),
            uint128(_creditCerUsd)
        );

        // remembering the position where new pool will be pushed to
        uint256 poolId = pools.length;
        pools.push(pool);

        // remembering poolId in the mapping
        tokenToPoolId[_token] = poolId;

        // minting 1000 lp tokens to prevent attack
        _mint(DEAD_ADDRESS, poolId, MINIMUM_LIQUIDITY, "");

        // minting initial lp tokens
        uint256 lpAmount = newSqrtKValue - MINIMUM_LIQUIDITY;
        _mint(_transferTo, poolId, lpAmount, "");

        // PoolCreated event is needed to track new pairs created in the graph node
        emit PoolCreated(_token, poolId);

        // LiquidityAdded event is needed to post in telegram channel
        emit LiquidityAdded(
            _token,
            _amountTokensIn,
            _amountCerUsdToMint,
            lpAmount
        );

        // Sync event to update pool variables in the graph node
        emit Sync(_token, _amountTokensIn, _amountCerUsdToMint, _creditCerUsd);
    }

    function addTokenLiquidity(
        address _token,
        uint256 _amountTokensIn,
        uint256 _expireTimestamp,
        address _transferTo
    )
        public
        payable
        tokenMustExistInPool(_token)
        transactionIsNotExpired(_expireTimestamp)
        returns (
            // checkForBots(msg.sender) // TODO: enable on production
            uint256
        )
    {
        // getting pool storage link (saves gas compared to memory)
        uint256 poolId = tokenToPoolId[_token];
        Pool storage pool = pools[poolId];

        // remembering balance before the transfer
        PoolBalances memory poolBalancesBefore = _getPoolBalances(
            _token,
            pool.vaultAddress
        );

        // safely transferring tokens from sender to the vault
        _safeTransferFromHelper(
            _token,
            msg.sender,
            pool.vaultAddress,
            _amountTokensIn
        );

        // remembering balance after the transfer
        PoolBalances memory poolBalancesAfter = _getPoolBalances(
            _token,
            pool.vaultAddress
        );

        // finding out how many tokens we've actually received
        _amountTokensIn =
            poolBalancesAfter.balanceToken -
            poolBalancesBefore.balanceToken;
        if (_amountTokensIn <= 1) {
            revert("F"); // TODO: remove this line on production
            revert CerbySwapV1_AmountOfTokensMustBeLargerThanOne();
        }

        // calculating new sqrt(k) value before updating pool
        uint256 newSqrtKValue = sqrt(
            poolBalancesBefore.balanceToken * poolBalancesBefore.balanceCerUsd
        );

        // calculating and minting LP trade fees
        uint256 amountLpTokensToMintAsFee = _getMintFeeLiquidityAmount(
            pool.lastSqrtKValue,
            newSqrtKValue,
            contractTotalSupply[poolId]
        );

        _mint(
            settings.mintFeeBeneficiary,
            poolId,
            amountLpTokensToMintAsFee,
            ""
        );

        // minting LP tokens
        uint256 lpAmount = (_amountTokensIn * contractTotalSupply[poolId]) /
            poolBalancesBefore.balanceToken;
        _mint(_transferTo, poolId, lpAmount, "");

        // scope to avoid stack to deep error
        // calculating amount of cerUSD to mint according to current price
        uint256 amountCerUsdToMint = (_amountTokensIn *
            poolBalancesBefore.balanceCerUsd) / poolBalancesBefore.balanceToken;
        if (amountCerUsdToMint <= 1) {
            revert CerbySwapV1_AmountOfCerUsdMustBeLargerThanOne();
        }

        // minting cerUSD according to current pool
        ICerbyTokenMinterBurner(cerUsdToken).mintHumanAddress(
            pool.vaultAddress,
            amountCerUsdToMint
        );

        // updating pool variables
        pool.lastSqrtKValue = uint128(
            sqrt(
                poolBalancesAfter.balanceToken * poolBalancesAfter.balanceCerUsd
            )
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
            poolBalancesAfter.balanceToken,
            poolBalancesAfter.balanceCerUsd,
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
        public
        tokenMustExistInPool(_token)
        transactionIsNotExpired(_expireTimestamp)
        returns (
            // checkForBots(msg.sender) // TODO: enable on production
            uint256
        )
    {
        return
            _removeTokenLiquidity(
                _token,
                _amountLpTokensBalanceToBurn,
                _transferTo
            );
    }

    function _removeTokenLiquidity(
        address _token,
        uint256 _amountLpTokensBalanceToBurn,
        address _transferTo
    ) private returns (uint256) {
        // getting pool storage link (saves gas compared to memory)
        uint256 poolId = tokenToPoolId[_token];
        Pool storage pool = pools[poolId];

        PoolBalances memory poolBalancesBefore = _getPoolBalances(
            _token,
            pool.vaultAddress
        );

        // calculating amount of tokens to transfer
        uint256 totalLPSupply = contractTotalSupply[poolId];
        uint256 amountTokensOut = (poolBalancesBefore.balanceToken *
            _amountLpTokensBalanceToBurn) / totalLPSupply;

        // calculating amount of cerUSD to burn
        uint256 amountCerUsdToBurn = (poolBalancesBefore.balanceCerUsd *
            _amountLpTokensBalanceToBurn) / totalLPSupply;

        // storing sqrt(k) value before updating pool
        uint256 newSqrtKValue = sqrt(
            poolBalancesBefore.balanceToken * poolBalancesBefore.balanceCerUsd
        );

        // minting trade fees
        uint256 amountLpTokensToMintAsFee = _getMintFeeLiquidityAmount(
            pool.lastSqrtKValue,
            newSqrtKValue,
            totalLPSupply
        );

        _mint(
            settings.mintFeeBeneficiary,
            poolId,
            amountLpTokensToMintAsFee,
            ""
        );

        // updating pool variables
        PoolBalances memory poolBalancesAfter = PoolBalances(
            poolBalancesBefore.balanceToken - amountTokensOut,
            poolBalancesBefore.balanceCerUsd - amountCerUsdToBurn
        );
        pool.lastSqrtKValue = uint128(
            sqrt(
                poolBalancesAfter.balanceToken * poolBalancesAfter.balanceCerUsd
            )
        );

        // burning LP tokens from sender (without approval)
        _burn(msg.sender, poolId, _amountLpTokensBalanceToBurn);

        // burning cerUSD
        ICerbyTokenMinterBurner(cerUsdToken).burnHumanAddress(
            pool.vaultAddress,
            amountCerUsdToBurn
        );

        // safely transfering tokens
        // and making sure exact amounts were actually transferred
        _safeTransferFromHelper(
            _token,
            pool.vaultAddress,
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
        uint256 _lastSqrtKValue,
        uint256 _newSqrtKValue,
        uint256 _totalLPSupply
    ) private view returns (uint256) {
        uint256 amountLpTokensToMintAsFee;
        uint256 mintFeeMultiplier = settings.mintFeeMultiplier;
        if (
            _newSqrtKValue > _lastSqrtKValue &&
            _lastSqrtKValue > 0 &&
            mintFeeMultiplier > 0
        ) {
            amountLpTokensToMintAsFee =
                (_totalLPSupply *
                    mintFeeMultiplier *
                    (_newSqrtKValue - _lastSqrtKValue)) /
                (_newSqrtKValue *
                    (MINT_FEE_DENORM - mintFeeMultiplier) +
                    _lastSqrtKValue *
                    mintFeeMultiplier);
        }

        return amountLpTokensToMintAsFee;
    }
}
