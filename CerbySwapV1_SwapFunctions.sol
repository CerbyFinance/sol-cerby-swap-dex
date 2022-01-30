// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.11;

import "./CerbySwapV1_GetFunctions.sol";
import "./CerbySwapV1_Modifiers.sol";
import "./CerbySwapV1_Math.sol";
import "./CerbySwapV1_ERC1155.sol";
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
            PoolBalances memory poolBalancesBefore = _getPoolBalances(_tokenIn);

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
            _safeTransferFromHelper(_tokenIn, msg.sender, _amountTokensIn);

            // swapping XXX ---> cerUSD
            _swap(_tokenIn, poolBalancesBefore, 0, amountTokensOut, _transferTo);
            return (_amountTokensIn, amountTokensOut);
        }

        // swaping cerUSD --> YYY
        if (_tokenIn == cerUsdToken && _tokenOut != cerUsdToken) {

            // getting pool balances before the swap
            PoolBalances memory poolBalancesBefore = _getPoolBalances(_tokenOut);

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
            _safeTransferFromHelper(_tokenIn, msg.sender, _amountTokensIn);

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
            PoolBalances memory firstPoolBalancesBefore = _getPoolBalances(_tokenIn);

            // getting amountTokensOut=
            uint256 amountCerUsdOut = _getOutputExactTokensForCerUsd(
                firstPoolBalancesBefore,
                _tokenIn,
                _amountTokensIn
            );

            // getting pool balances before the swap
            PoolBalances memory secondPoolBalancesBefore = _getPoolBalances(_tokenOut);

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
            _safeTransferFromHelper(_tokenIn, msg.sender, _amountTokensIn);

            // swapping XXX ---> cerUSD
            // keeping all output cerUSD in the contract without sending
            _swap(_tokenIn, firstPoolBalancesBefore, 0, amountCerUsdOut, address(this));

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
            PoolBalances memory poolBalancesBefore = _getPoolBalances(_tokenIn);

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
            _safeTransferFromHelper(_tokenIn, msg.sender, amountTokensIn);

            // swapping XXX ---> cerUSD
            _swap(_tokenIn, poolBalancesBefore, 0, _amountTokensOut, _transferTo);

            return (amountTokensIn, _amountTokensOut);
        }

        // swapping cerUSD --> YYY
        if (_tokenIn == cerUsdToken && _tokenOut != cerUsdToken) {

            // getting pool balances before the swap
            PoolBalances memory poolBalancesBefore = _getPoolBalances(_tokenIn);

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
            _safeTransferFromHelper(_tokenIn, msg.sender, amountTokensIn);

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
            PoolBalances memory firstPoolBalancesBefore = _getPoolBalances(_tokenIn);

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
            PoolBalances memory secondPoolBalancesBefore = _getPoolBalances(_tokenOut);

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
            _safeTransferFromHelper(_tokenIn, msg.sender, amountTokensIn);

            // swapping XXX ---> cerUSD
            _swap(_tokenIn, firstPoolBalancesBefore, 0, amountCerUsdOut, address(this));

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

        PoolBalances memory poolBalancesAfter = _getPoolBalances(_token);

        // finding out how many amountCerUsdIn we received
        uint256 amountCerUsdIn = poolBalancesAfter.balanceCerUsd -
            totalCerUsdBalance;

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

        {
            // scope to avoid stack too deep error

            // checking if cerUsd credit is enough to cover this swap
            if (
                pool.creditCerUsd < type(uint256).max &&
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
            uint256 _totalCerUsdBalance = totalCerUsdBalance +
                amountCerUsdIn -
                _amountCerUsdOut;
            uint256 _balanceCerUsd = uint256(pool.balanceCerUsd) +
                amountCerUsdIn -
                _amountCerUsdOut;
            poolBalancesAfter.balanceToken -= _amountTokensOut;

            // calculating new K value including trade fees
            uint256 afterKValueDenormed = (_balanceCerUsd *
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

            // updating pool values
            totalCerUsdBalance = _totalCerUsdBalance;
            pool.balanceCerUsd = uint128(_balanceCerUsd);

            // updating creditCerUsd only if pool is user-created
            if (pool.creditCerUsd < type(uint256).max) {
                pool.creditCerUsd =
                    pool.creditCerUsd +
                    amountCerUsdIn -
                    _amountCerUsdOut;
            }
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
        _safeTransferHelper(_token, _transferTo, _amountTokensOut, true);

        // safely transfering cerUSD
        _safeTransferHelper(cerUsdToken, _transferTo, _amountCerUsdOut, true);

        // Swap event is needed to post in telegram channel
        /*emit Swap(
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
            pool.balanceToken,
            pool.balanceCerUsd,
            pool.creditCerUsd
        );*/
    }



    // ---------------------------------------------- //

    // user can increase cerUsd credit in the pool
    function increaseCerUsdCreditInPool(
        address _token,
        uint256 _amountCerUsdCredit
    ) public {
        // getting pool storage link (saves gas compared to memory)
        Pool storage pool = pools[tokenToPoolId[_token]];

        // handling overflow just in case
        if (pool.creditCerUsd < type(uint256).max) {
            // increasing credit for user-created pool
            pool.creditCerUsd += _amountCerUsdCredit;

            // burning user's cerUsd tokens in order to increase the credit for given pool
            ICerbyTokenMinterBurner(cerUsdToken).burnHumanAddress(
                msg.sender,
                _amountCerUsdCredit
            );
        }

        // Sync event to update pool variables in the graph node
        /*emit Sync(
            _token,
            pool.balanceToken,
            pool.balanceCerUsd,
            pool.creditCerUsd
        );*/
    }

    // only users are allowed to create new pools with creditCerUsd = 0
    function createPool(
        address token,
        uint256 amountTokensIn,
        uint256 amountCerUsdToMint,
        address transferTo
    ) public payable {
        _createPool(
            token,
            amountTokensIn,
            amountCerUsdToMint,
            0, // creditCerUsd
            transferTo
        );
    }

    function _createPool(
        address token,
        uint256 amountTokensIn,
        uint256 amountCerUsdToMint,
        uint256 creditCerUsd,
        address transferTo
    ) internal tokenDoesNotExistInPool(token) {
        // safely transferring tokens from sender to this contract
        // or doing nothing if msg.value specified correctly
        _safeTransferFromHelper(token, msg.sender, amountTokensIn);

        // minting requested amount of cerUSD tokens to this contract
        ICerbyTokenMinterBurner(cerUsdToken).mintHumanAddress(
            address(this),
            amountCerUsdToMint
        );

        // finding out how many tokens router have sent to us
        amountTokensIn = _getTokenBalance(token);
        if (amountTokensIn <= 1) {
            revert("F"); // TODO: remove this line on production
            revert CerbySwapV1_AmountOfTokensMustBeLargerThanOne();
        }

        // create new pool record
        uint256 newSqrtKValue = sqrt(amountTokensIn * amountCerUsdToMint);

        // filling with 1 usd per hour in trades to reduce gas later
        uint32[NUMBER_OF_TRADE_PERIODS] memory tradeVolumePerPeriodInCerUsd;
        for (uint256 i; i < NUMBER_OF_TRADE_PERIODS; i++) {
            tradeVolumePerPeriodInCerUsd[i] = 1;
        }

        // preparing pool object to push into storage
        Pool memory pool = Pool(
            tradeVolumePerPeriodInCerUsd,
            uint128(amountCerUsdToMint),
            uint128(newSqrtKValue),
            creditCerUsd
        );

        // remembering the position where new pool will be pushed to
        uint256 poolId = pools.length;
        pools.push(pool);

        // remembering poolId in the mapping
        tokenToPoolId[token] = poolId;

        unchecked {
            totalCerUsdBalance += amountCerUsdToMint;
        }

        // minting 1000 lp tokens to prevent attack
        _mint(DEAD_ADDRESS, poolId, MINIMUM_LIQUIDITY, "");

        // minting initial lp tokens
        uint256 lpAmount = newSqrtKValue - MINIMUM_LIQUIDITY;
        _mint(transferTo, poolId, lpAmount, "");

        // PairCreated event is needed to track new pairs created in the graph node
        emit PairCreated(token, poolId);

        // LiquidityAdded event is needed to post in telegram channel
        emit LiquidityAdded(
            token,
            amountTokensIn,
            amountCerUsdToMint,
            lpAmount
        );

        // Sync event to update pool variables in the graph node
        /*emit Sync(
            token,
            pool.balanceToken,
            pool.balanceCerUsd,
            pool.creditCerUsd
        );*/
    }

    function addTokenLiquidity(
        address token,
        uint256 amountTokensIn,
        uint256 expireTimestamp,
        address transferTo
    )
        public
        payable
        tokenMustExistInPool(token)
        transactionIsNotExpired(expireTimestamp)
        returns (
            // checkForBots(msg.sender) // TODO: enable on production
            uint256
        )
    {
        // getting pool storage link (saves gas compared to memory)
        uint256 poolId = tokenToPoolId[token];
        Pool storage pool = pools[poolId];

        PoolBalances memory poolBalancesBefore = _getPoolBalances(token);

        // safely transferring tokens from sender to this contract
        // or doing nothing if msg.value specified correctly
        _safeTransferFromHelper(token, msg.sender, amountTokensIn);

        PoolBalances memory poolBalancesAfter = _getPoolBalances(token);

        // finding out how many tokens we've actually received
        amountTokensIn = poolBalancesAfter.balanceToken - poolBalancesBefore.balanceToken;
        if (amountTokensIn <= 1) {
            revert("F"); // TODO: remove this line on production
            revert CerbySwapV1_AmountOfTokensMustBeLargerThanOne();
        }

        // finding out if for some reason we've received cerUSD tokens as well
        uint256 amountCerUsdIn = poolBalancesAfter.balanceCerUsd - totalCerUsdBalance;

        {
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
        }

        // minting LP tokens
        uint256 lpAmount = (amountTokensIn * contractTotalSupply[poolId]) /
            poolBalancesBefore.balanceToken;
        _mint(transferTo, poolId, lpAmount, "");

        {
            // scope to avoid stack to deep error
            // calculating amount of cerUSD to mint according to current price
            uint256 amountCerUsdToMint = amountTokensIn *
                poolBalancesBefore.balanceCerUsd / poolBalancesBefore.balanceToken;
            if (amountCerUsdToMint <= 1) {
                revert CerbySwapV1_AmountOfCerUsdMustBeLargerThanOne();
            }

            // minting cerUSD according to current pool
            ICerbyTokenMinterBurner(cerUsdToken).mintHumanAddress(
                address(this),
                amountCerUsdToMint
            );

            // updating pool variables
            totalCerUsdBalance =
                totalCerUsdBalance +
                amountCerUsdIn +
                amountCerUsdToMint;
            pool.balanceCerUsd =
                pool.balanceCerUsd +
                uint128(amountCerUsdIn + amountCerUsdToMint);
            pool.lastSqrtKValue = uint128(
                sqrt(poolBalancesBefore.balanceToken * poolBalancesBefore.balanceCerUsd)
            );

            // LiquidityAdded event is needed to post in telegram channel
            emit LiquidityAdded(
                token,
                amountTokensIn,
                amountCerUsdToMint,
                lpAmount
            );

            // Sync event to update pool variables in the graph node
            /*emit Sync(
                token,
                pool.balanceToken,
                pool.balanceCerUsd,
                pool.creditCerUsd
            );*/
        }

        return lpAmount;
    }

    function removeTokenLiquidity(
        address token,
        uint256 amountLpTokensBalanceToBurn,
        uint256 expireTimestamp,
        address transferTo
    )
        public
        tokenMustExistInPool(token)
        transactionIsNotExpired(expireTimestamp)
        returns (
            // checkForBots(msg.sender) // TODO: enable on production
            uint256
        )
    {
        return
            _removeTokenLiquidity(
                token,
                amountLpTokensBalanceToBurn,
                transferTo
            );
    }

    function _removeTokenLiquidity(
        address token,
        uint256 amountLpTokensBalanceToBurn,
        address transferTo
    ) private returns (uint256) {
        // getting pool storage link (saves gas compared to memory)
        uint256 poolId = tokenToPoolId[token];
        Pool storage pool = pools[poolId];

        PoolBalances memory poolBalancesBefore = _getPoolBalances(token);

        // finding out if for some reason we've received cerUSD tokens as well
        uint256 amountCerUsdIn = poolBalancesBefore.balanceCerUsd -
            totalCerUsdBalance;

        // calculating amount of tokens to transfer
        uint256 totalLPSupply = contractTotalSupply[poolId];
        uint256 amountTokensOut = poolBalancesBefore.balanceToken *
            amountLpTokensBalanceToBurn / totalLPSupply;

        // calculating amount of cerUSD to burn
        uint256 amountCerUsdToBurn = (uint256(pool.balanceCerUsd) *
            amountLpTokensBalanceToBurn) / totalLPSupply;

        {
            // scope to avoid stack too deep error
            // storing sqrt(k) value before updating pool
            uint256 newSqrtKValue = sqrt(
                poolBalancesBefore.balanceToken * poolBalancesBefore.balanceCerUsd)
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
            totalCerUsdBalance =
                totalCerUsdBalance +
                amountCerUsdIn -
                amountCerUsdToBurn;
            pool.balanceCerUsd =
                pool.balanceCerUsd +
                uint128(amountCerUsdIn) -
                uint128(amountCerUsdToBurn);

            pool.lastSqrtKValue = uint128(
                sqrt((poolBalancesBefore.balanceToken - amountTokensOut) * uint256(pool.balanceCerUsd))
            );

            // burning LP tokens from sender (without approval)
            _burn(msg.sender, poolId, amountLpTokensBalanceToBurn);

            // burning cerUSD
            ICerbyTokenMinterBurner(cerUsdToken).burnHumanAddress(
                address(this),
                amountCerUsdToBurn
            );
        }

        // safely transfering tokens
        // and making sure exact amounts were actually transferred
        _safeTransferHelper(token, transferTo, amountTokensOut, true);

        // LiquidityRemoved event is needed to post in telegram channel
        emit LiquidityRemoved(
            token,
            amountTokensOut,
            amountCerUsdToBurn,
            amountLpTokensBalanceToBurn
        );

        // Sync event to update pool variables in the graph node
        emit Sync(
            token,
            pool.balanceToken,
            pool.balanceCerUsd,
            pool.creditCerUsd
        );

        return amountTokensOut;
    }

    function syncPool(address token)
        public
        tokenMustExistInPool(token)
    // checkForBotsAndExecuteCronJobs(msg.sender) // TODO: enable on production
    {
        // getting pool storage link (saves gas compared to memory)
        uint256 poolId = tokenToPoolId[token];
        Pool storage pool = pools[poolId];

        // updating current token balance in pool
        pool.balanceToken = uint128(_getTokenBalance(token));

        // updating current cerUSD balance in pool
        uint256 newTotalCerUsdBalance = _getTokenBalance(cerUsdToken);
        pool.balanceCerUsd = uint128(
            uint256(pool.balanceCerUsd) +
                newTotalCerUsdBalance -
                totalCerUsdBalance
        );

        // updating current cerUSD credit in pool
        // only for user-created pools
        if (pool.creditCerUsd < type(uint256).max) {
            pool.creditCerUsd =
                pool.creditCerUsd +
                newTotalCerUsdBalance -
                totalCerUsdBalance;
        }

        // updating global cerUsd balance in contract
        totalCerUsdBalance = newTotalCerUsdBalance;

        // Sync event to update pool variables in the graph node
        emit Sync(
            token,
            pool.balanceToken,
            pool.balanceCerUsd,
            pool.creditCerUsd
        );
    }

    function _getMintFeeLiquidityAmount(
        uint256 lastSqrtKValue,
        uint256 newSqrtKValue,
        uint256 totalLPSupply
    ) private view returns (uint256) {
        uint256 amountLpTokensToMintAsFee;
        uint256 mintFeeMultiplier = settings.mintFeeMultiplier;
        if (
            newSqrtKValue > lastSqrtKValue &&
            lastSqrtKValue > 0 &&
            mintFeeMultiplier > 0
        ) {
            amountLpTokensToMintAsFee =
                (totalLPSupply *
                    mintFeeMultiplier *
                    (newSqrtKValue - lastSqrtKValue)) /
                (newSqrtKValue *
                    (MINT_FEE_DENORM - mintFeeMultiplier) +
                    lastSqrtKValue *
                    mintFeeMultiplier);
        }

        return amountLpTokensToMintAsFee;
    }
}
