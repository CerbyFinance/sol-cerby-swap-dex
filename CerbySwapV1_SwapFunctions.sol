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

            // getting pool balances before the swap
            address vaultAddressIn = pools[tokenToPoolId[_tokenIn]].vaultAddress;
            PoolBalances memory poolBalancesBefore = _getPoolBalances(_tokenIn, vaultAddressIn);

            // getting amountTokensOut
            amountTokensOut = _getOutputExactTokensForCerUsd(
                poolBalancesBefore,
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
            _safeTransferFromHelper(_tokenIn, msg.sender, vaultAddressIn, _amountTokensIn);

            // swapping XXX ---> cerUSD
            _swap(_tokenIn, poolBalancesBefore, 0, amountTokensOut, _transferTo);
            return (_amountTokensIn, amountTokensOut);
        }

        // swaping cerUSD --> YYY
        if (_tokenIn == cerUsdToken && _tokenOut != cerUsdToken) {

            // getting pool balances before the swap
            address vaultAddressOut = pools[tokenToPoolId[_tokenOut]].vaultAddress;
            PoolBalances memory poolBalancesBefore = _getPoolBalances(_tokenOut, vaultAddressOut);

            // getting amountTokensOut
            amountTokensOut = _getOutputExactCerUsdForTokens(
                poolBalancesBefore,
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
            _safeTransferFromHelper(_tokenIn, msg.sender, vaultAddressOut, _amountTokensIn);

            // swapping cerUSD ---> YYY
            _swap(_tokenOut, poolBalancesBefore, amountTokensOut, 0, _transferTo);

            return (_amountTokensIn, amountTokensOut);
            // TODO: uncomment below
        }

        // swaping XXX --> cerUsd --> YYY (or XXX --> YYY)
        if (
            _tokenIn != cerUsdToken &&
            _tokenOut != cerUsdToken &&
            _tokenIn != _tokenOut
        ) {
            // getting pool balances before the swap
            address vaultAddressIn = pools[tokenToPoolId[_tokenIn]].vaultAddress;
            PoolBalances memory firstPoolBalancesBefore = _getPoolBalances(_tokenIn, vaultAddressIn);

            // getting amountTokensOut=
            uint256 amountCerUsdOut = _getOutputExactTokensForCerUsd(
                firstPoolBalancesBefore,
                _tokenIn,
                _amountTokensIn
            );

            // getting pool balances before the swap
            address vaultAddressOut = pools[tokenToPoolId[_tokenOut]].vaultAddress;
            PoolBalances memory secondPoolBalancesBefore = _getPoolBalances(_tokenOut, vaultAddressOut);

            amountTokensOut = _getOutputExactCerUsdForTokens(
                secondPoolBalancesBefore,
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
            _safeTransferFromHelper(_tokenIn, msg.sender, vaultAddressIn, _amountTokensIn);

            // swapping XXX ---> cerUSD
            // keeping all output cerUSD in the contract without sending
            _swap(_tokenIn, firstPoolBalancesBefore, 0, amountCerUsdOut, address(this));

            _safeTransferFromHelper(cerUsdToken, vaultAddressIn, vaultAddressOut, amountCerUsdOut);

            // swapping cerUSD ---> YYY
            _swap(_tokenOut, secondPoolBalancesBefore, amountTokensOut, 0, _transferTo);
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
        public
        payable
        transactionIsNotExpired(_expireTimestamp)
        returns (
            // checkForBots(msg.sender) // TODO: enable on production
            uint256,
            uint256
        )
    {
        uint256 amountTokensIn;

        // swapping XXX --> cerUSD
        if (_tokenIn != cerUsdToken && _tokenOut == cerUsdToken) {

            // getting pool balances before the swap
            address vaultAddressIn = pools[tokenToPoolId[_tokenIn]].vaultAddress;
            PoolBalances memory poolBalancesBefore = _getPoolBalances(_tokenIn, vaultAddressIn);

            // getting amountTokensOut
            amountTokensIn = _getInputTokensForExactCerUsd(
                poolBalancesBefore,
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
            _safeTransferFromHelper(_tokenIn, msg.sender, vaultAddressIn, amountTokensIn);

            // swapping XXX ---> cerUSD
            _swap(_tokenIn, poolBalancesBefore, 0, _amountTokensOut, _transferTo);

            return (amountTokensIn, _amountTokensOut);
        }

        // swapping cerUSD --> YYY
        if (_tokenIn == cerUsdToken && _tokenOut != cerUsdToken) {

            // getting pool balances before the swap
            address vaultAddressOut = pools[tokenToPoolId[_tokenOut]].vaultAddress;
            PoolBalances memory poolBalancesBefore = _getPoolBalances(_tokenOut, vaultAddressOut);

            // getting amountTokensOut
            amountTokensIn = _getInputCerUsdForExactTokens(
                poolBalancesBefore,
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
            _safeTransferFromHelper(_tokenIn, msg.sender, vaultAddressOut, amountTokensIn);

            // swapping cerUSD ---> YYY
            _swap(_tokenOut, poolBalancesBefore, _amountTokensOut, 0, _transferTo);

            return (amountTokensIn, _amountTokensOut);
        }

        // swaping XXX --> cerUsd --> YYY (or XXX --> YYY)
        if (
            _tokenIn != cerUsdToken &&
            _tokenOut != cerUsdToken &&
            _tokenIn != _tokenOut
        ) {
            // getting pool balances before the swap
            address vaultAddressIn = pools[tokenToPoolId[_tokenIn]].vaultAddress;
            PoolBalances memory firstPoolBalancesBefore = _getPoolBalances(_tokenIn, vaultAddressIn);

            // getting amountTokensOut
            uint256 amountCerUsdOut = _getInputCerUsdForExactTokens(
                firstPoolBalancesBefore,
                _tokenIn,
                _amountTokensOut
            );

            // amountCerUsdOut must be larger than 1 to avoid rounding errors
            if (amountCerUsdOut <= 1) {
                revert("U"); // TODO: remove this line on production
                revert CerbySwapV1_AmountOfCerUsdMustBeLargerThanOne();
            }

            // getting pool balances before the swap
            address vaultAddressOut = pools[tokenToPoolId[_tokenOut]].vaultAddress;
            PoolBalances memory secondPoolBalancesBefore = _getPoolBalances(_tokenOut, vaultAddressOut);

            amountTokensIn = _getInputTokensForExactCerUsd(
                secondPoolBalancesBefore,
                _tokenOut,
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
            _safeTransferFromHelper(_tokenIn, msg.sender, vaultAddressIn, amountTokensIn);

            // swapping XXX ---> cerUSD
            _swap(_tokenIn, firstPoolBalancesBefore, 0, amountCerUsdOut, address(this));

            _safeTransferFromHelper(cerUsdToken, vaultAddressIn, vaultAddressOut, amountCerUsdOut);

            // swapping cerUSD ---> YYY
            _swap(_tokenOut, secondPoolBalancesBefore, _amountTokensOut, 0, _transferTo);

            return (amountTokensIn, _amountTokensOut);
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

        PoolBalances memory poolBalancesAfter = _getPoolBalances(_token, pool.vaultAddress);

        // finding out how many amountCerUsdIn we received
        uint256 amountCerUsdIn = poolBalancesAfter.balanceCerUsd -
            _poolBalancesBefore.balanceCerUsd;

        // finding out how many amountTokensIn we received
        uint256 amountTokensIn = poolBalancesAfter.balanceToken - _poolBalancesBefore.balanceToken;
        if (amountTokensIn + amountCerUsdIn <= 1) {
            revert("2");
            revert CerbySwapV1_AmountOfCerUsdOrTokensInMustBeLargerThanOne();
        }

        // calculating fees
        // if swap is ANY --> cerUSD, fee is calculated
        // if swap is cerUSD --> ANY, fee is zero
        uint256 oneMinusFee = amountCerUsdIn > 1 && amountTokensIn <= 1
            ? FEE_DENORM
            : _getCurrentOneMinusFeeBasedOnTrades(pool, _poolBalancesBefore);

        // checking if cerUsd credit is enough to cover this swap
        if (
            pool.creditCerUsd < type(uint128).max &&
            pool.creditCerUsd + amountCerUsdIn < _amountCerUsdOut
        ) {
            revert("Z");
            revert CerbySwapV1_CreditCerUsdMustNotBeBelowZero();
        }

        // calculating old K value including trade fees (multiplied by FEE_DENORM^2)
        uint256 beforeKValueDenormed = _poolBalancesBefore.balanceToken *
            _poolBalancesBefore.balanceCerUsd *
            FEE_DENORM_SQUARED;

        // calculating new pool values
        poolBalancesAfter.balanceToken = poolBalancesAfter.balanceToken + amountTokensIn -
            _amountTokensOut;
        poolBalancesAfter.balanceCerUsd = poolBalancesAfter.balanceCerUsd + amountCerUsdIn -
            _amountCerUsdOut;

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
        if (pool.creditCerUsd < type(uint128).max) {
            pool.creditCerUsd =
                uint128(
                    uint(pool.creditCerUsd) +
                    amountCerUsdIn -
                    _amountCerUsdOut
                );
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
        _safeTransferFromHelper(_token, pool.vaultAddress, _transferTo, _amountTokensOut);

        // safely transfering cerUSD
        _safeTransferFromHelper(cerUsdToken, pool.vaultAddress, _transferTo, _amountCerUsdOut);

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

        PoolBalances memory poolBalances = _getPoolBalances(_token, pool.vaultAddress);

        if (pool.creditCerUsd < type(uint128).max) {
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

        // using current contract as a vault for native tokens
        address vaultAddress = address(this);
        
        // creating vault contract for non-native tokens
        if (_token != nativeToken) {
            vaultAddress = address(new CerbySwapV1_Vault(_token));
        }

        // safely transferring tokens from sender to this contract
        // or doing nothing if msg.value specified correctly
        _safeTransferFromHelper(_token, msg.sender, vaultAddress, _amountTokensIn);

        // minting requested amount of cerUSD tokens to this contract
        ICerbyTokenMinterBurner(cerUsdToken).mintHumanAddress(
            vaultAddress,
            _amountCerUsdToMint
        );

        // finding out how many tokens received
        _amountTokensIn = IERC20(_token).balanceOf(vaultAddress);
        if (_amountTokensIn <= 1) {
            revert("F"); // TODO: remove this line on production
            revert CerbySwapV1_AmountOfTokensMustBeLargerThanOne();
        }

        // create new pool record
        uint256 newSqrtKValue = sqrt(_amountTokensIn * _amountCerUsdToMint);

        // preparing pool object to push into storage
        uint32[NUMBER_OF_TRADE_PERIODS] memory tradeVolumePerPeriodInCerUsd;
        Pool memory pool = Pool(
            vaultAddress,
            tradeVolumePerPeriodInCerUsd,
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

        // PairCreated event is needed to track new pairs created in the graph node
        emit PairCreated(_token, poolId);

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
        PoolBalances memory poolBalancesBefore = _getPoolBalances(_token, pool.vaultAddress);

        // safely transferring tokens from sender to this contract
        // or doing nothing if msg.value specified correctly
        _safeTransferFromHelper(_token, msg.sender, pool.vaultAddress, _amountTokensIn);

        // remembering balance after the transfer
        PoolBalances memory poolBalancesAfter = _getPoolBalances(_token, pool.vaultAddress);

        // finding out how many tokens we've actually received
        _amountTokensIn = poolBalancesAfter.balanceToken - poolBalancesBefore.balanceToken;
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
        uint256 lpAmount = _amountTokensIn * contractTotalSupply[poolId] /
            poolBalancesBefore.balanceToken;
        _mint(_transferTo, poolId, lpAmount, "");

        
        // scope to avoid stack to deep error
        // calculating amount of cerUSD to mint according to current price
        uint256 amountCerUsdToMint = _amountTokensIn *
            poolBalancesBefore.balanceCerUsd / poolBalancesBefore.balanceToken;
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
            sqrt(poolBalancesAfter.balanceToken * poolBalancesAfter.balanceCerUsd)
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

        PoolBalances memory poolBalancesBefore = _getPoolBalances(_token, pool.vaultAddress);

        // calculating amount of tokens to transfer
        uint256 totalLPSupply = contractTotalSupply[poolId];
        uint256 amountTokensOut = poolBalancesBefore.balanceToken *
            _amountLpTokensBalanceToBurn / totalLPSupply;

        // calculating amount of cerUSD to burn
        uint256 amountCerUsdToBurn = poolBalancesBefore.balanceCerUsd *
            _amountLpTokensBalanceToBurn / totalLPSupply;

        
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
        PoolBalances memory poolBalancesAfter = Pool(
            poolBalancesBefore.balanceToken - amountTokensOut,
            poolBalancesBefore.balanceCerUsd - amountCerUsdToBurn
        );
        pool.lastSqrtKValue = uint128(
            sqrt(poolBalancesAfter.balanceToken * poolBalancesAfter.balanceCerUsd)
        );

        // burning LP tokens from sender (without approval)
        _burn(msg.sender, poolId, _amountLpTokensBalanceToBurn);

        // burning cerUSD
        ICerbyTokenMinterBurner(cerUsdToken).burnHumanAddress(
            address(this),
            amountCerUsdToBurn
        );
    

        // safely transfering tokens
        // and making sure exact amounts were actually transferred
        _safeTransferFromHelper(_token, pool.vaultAddress, _transferTo, amountTokensOut);

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
