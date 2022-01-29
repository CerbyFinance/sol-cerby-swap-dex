// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.11;

import "./interfaces/ICerbyTokenMinterBurner.sol";
import "./CerbySwapV1_Modifiers.sol";
import "./CerbySwapV1_Math.sol";
import "./CerbySwapV1_SafeFunctions.sol";
import "./CerbySwapV1_ERC1155.sol";

abstract contract CerbySwapV1_LiquidityFunctions is CerbySwapV1_SafeFunctions, CerbySwapV1_Modifiers, 
    CerbySwapV1_Math, CerbySwapV1_ERC1155
{


    // user can increase cerUsd credit in the pool
    function increaseCerUsdCreditInPool(
        address token,
        uint amountCerUsdCredit
    )
        public
    {
        uint poolId = tokenToPoolId[token];

        // handling overflow just in case
        if (pools[poolId].creditCerUsd > type(uint).max - amountCerUsdCredit) {
            revert("X");
            revert CerbySwapV1_CreditCerUsdIsOverflown();
        }

        // increasing credit for user-created pool
        pools[poolId].creditCerUsd += amountCerUsdCredit;

        // burning user's cerUsd tokens in order to increase the credit for given pool
        ICerbyTokenMinterBurner(cerUsdToken).burnHumanAddress(msg.sender, amountCerUsdCredit);

        emit Sync(
            token, 
            pools[poolId].balanceToken, 
            pools[poolId].balanceCerUsd,
            pools[poolId].creditCerUsd
        );
    }

    // only users are allowed to create new pools with creditCerUsd = 0
    function createPool(
        address token, 
        uint amountTokensIn, 
        uint amountCerUsdToMint, 
        address transferTo
    )
        public
        payable
    {
        _createPool(
            token, 
            amountTokensIn, 
            amountCerUsdToMint, 
            0,
            transferTo
        );
    }

    function _createPool(
        address token, 
        uint amountTokensIn, 
        uint amountCerUsdToMint, 
        uint creditCerUsd,
        address transferTo
    )
        internal
        tokenDoesNotExistInPool(token)
    {
        _safeTransferFromHelper(token, msg.sender, amountTokensIn);
        ICerbyTokenMinterBurner(cerUsdToken).mintHumanAddress(address(this), amountCerUsdToMint);

        // finding out how many tokens router have sent to us
        amountTokensIn = _getTokenBalance(token);
        if (
            amountTokensIn <= 1
        ) {
            revert("F"); // TODO: remove this line on production
            revert CerbySwapV1_AmountOfTokensMustBeLargerThanOne();
        }

        // create new pool record
        uint newSqrtKValue = sqrt(uint(amountTokensIn) * uint(amountCerUsdToMint));

        // filling with 1 usd per hour in trades to reduce gas later
        uint32[NUMBER_OF_TRADE_PERIODS] memory tradeVolumePerPeriodInCerUsd;
        for(uint i; i<NUMBER_OF_TRADE_PERIODS; i++) {
            tradeVolumePerPeriodInCerUsd[i] = 1;
        }

        Pool memory pool = Pool(
            tradeVolumePerPeriodInCerUsd,
            uint128(amountTokensIn),
            uint128(amountCerUsdToMint),
            uint128(newSqrtKValue),
            creditCerUsd
        );

        uint poolId = pools.length; // remembering last position where pool will be pushed to
        pools.push(pool);

        tokenToPoolId[token] = poolId;   
        totalCerUsdBalance += amountCerUsdToMint;

        // minting 1000 lp tokens to prevent attack
        _mint(
            DEAD_ADDRESS,
            poolId,
            MINIMUM_LIQUIDITY,
            ""
        );

        // minting initial lp tokens
        uint lpAmount = sqrt(amountTokensIn * amountCerUsdToMint) - MINIMUM_LIQUIDITY;
        _mint(
            transferTo,
            poolId,
            lpAmount,
            ""
        );

        emit PairCreated(
            token,
            poolId
        );

        emit LiquidityAdded(
            token, 
            amountTokensIn, 
            amountCerUsdToMint, 
            lpAmount
        );
        
        emit Sync(
            token, 
            pools[poolId].balanceToken, 
            pools[poolId].balanceCerUsd,
            pools[poolId].creditCerUsd
        );
    }

    function addTokenLiquidity(
        address token, 
        uint amountTokensIn, 
        uint expireTimestamp,
        address transferTo
    )
        public
        payable
        tokenMustExistInPool(token)
        transactionIsNotExpired(expireTimestamp)
        // checkForBots(msg.sender) // TODO: enable on production
        returns (uint)
    {
        uint poolId = tokenToPoolId[token];

        _safeTransferFromHelper(token, msg.sender, amountTokensIn);

        // finding out how many tokens we've actually received
        uint newTokenBalance = _getTokenBalance(token);
        amountTokensIn = newTokenBalance - pools[poolId].balanceToken;
        if (
            amountTokensIn <= 1
        ) {
            revert("F"); // TODO: remove this line on production
            revert CerbySwapV1_AmountOfTokensMustBeLargerThanOne();
        }

        // finding out if for some reason we've received cerUSD tokens as well
        uint newTotalCerUsdBalance = _getTokenBalance(cerUsdToken);
        uint amountCerUsdIn = newTotalCerUsdBalance - totalCerUsdBalance;

        {
            // calculating new sqrt(k) value before updating pool
            uint newSqrtKValue = 
                sqrt(uint(pools[poolId].balanceToken) * 
                        uint(pools[poolId].balanceCerUsd));
            
            // minting trade fees
            uint amountLpTokensToMintAsFee = 
                _getMintFeeLiquidityAmount(
                    pools[poolId].lastSqrtKValue, 
                    newSqrtKValue, 
                    _totalSupply[poolId]
                );

            if (amountLpTokensToMintAsFee > 0) {
                _mint(
                    settings.mintFeeBeneficiary, 
                    poolId, 
                    amountLpTokensToMintAsFee,
                    ""
                );
            }
        }

        // minting LP tokens
        uint lpAmount = (amountTokensIn * _totalSupply[poolId]) / pools[poolId].balanceToken;
        _mint(
            transferTo,
            poolId,
            lpAmount,
            ""
        );     

        { // scope to avoid stack to deep error
            // calculating amount of cerUSD to mint according to current price
            uint amountCerUsdToMint = 
                (amountTokensIn * uint(pools[poolId].balanceCerUsd)) / 
                    uint(pools[poolId].balanceToken);
            if (
                amountCerUsdToMint <= 1
            ) {
                revert CerbySwapV1_AmountOfCerUsdMustBeLargerThanOne();
            }

            // minting cerUSD according to current pool
            ICerbyTokenMinterBurner(cerUsdToken).mintHumanAddress(address(this), amountCerUsdToMint);

            // updating pool
            totalCerUsdBalance = totalCerUsdBalance + amountCerUsdIn + amountCerUsdToMint;
            pools[poolId].balanceToken = 
                pools[poolId].balanceToken + uint128(amountTokensIn);
            pools[poolId].balanceCerUsd = 
                pools[poolId].balanceCerUsd + uint128(amountCerUsdIn + amountCerUsdToMint);
            pools[poolId].lastSqrtKValue = 
                uint128(sqrt(uint(pools[poolId].balanceToken) * 
                    uint(pools[poolId].balanceCerUsd)));

            emit LiquidityAdded(
                token, 
                amountTokensIn, 
                amountCerUsdToMint, 
                lpAmount
            );

            emit Sync(
                token, 
                pools[poolId].balanceToken, 
                pools[poolId].balanceCerUsd,
                pools[poolId].creditCerUsd
            );
        }

        return lpAmount;
    }

    function removeTokenLiquidity(
        address token, 
        uint amountLpTokensBalanceToBurn, 
        uint expireTimestamp,
        address transferTo
    )
        public
        tokenMustExistInPool(token)
        transactionIsNotExpired(expireTimestamp)
        // checkForBots(msg.sender) // TODO: enable on production
        returns (uint)
    {
        return _removeTokenLiquidity(
            token,
            amountLpTokensBalanceToBurn,
            transferTo
        );
    }

    function _removeTokenLiquidity(
        address token, 
        uint amountLpTokensBalanceToBurn, 
        address transferTo
    )
        private
        returns (uint)
    {
        uint poolId = tokenToPoolId[token];
        
        // finding out if for some reason we've received tokens
        uint oldTokenBalance = _getTokenBalance(token);
        uint amountTokensIn = oldTokenBalance - pools[poolId].balanceToken;

        // finding out if for some reason we've received cerUSD tokens as well
        uint amountCerUsdIn = _getTokenBalance(cerUsdToken) - totalCerUsdBalance;

        // calculating amount of tokens to transfer
        uint totalLPSupply = _totalSupply[poolId];
        uint amountTokensOut = 
            (uint(pools[poolId].balanceToken) * amountLpTokensBalanceToBurn) / totalLPSupply;       

        // calculating amount of cerUSD to burn
        uint amountCerUsdToBurn = 
            (uint(pools[poolId].balanceCerUsd) * amountLpTokensBalanceToBurn) / totalLPSupply;

        { // scope to avoid stack too deep error                
            // storing sqrt(k) value before updating pool
            uint newSqrtKValue = 
                sqrt(uint(pools[poolId].balanceToken) * 
                    uint(pools[poolId].balanceCerUsd));

            // minting trade fees
            uint amountLpTokensToMintAsFee = 
                _getMintFeeLiquidityAmount(
                    pools[poolId].lastSqrtKValue, 
                    newSqrtKValue, 
                    totalLPSupply
                );

            if (amountLpTokensToMintAsFee > 0) {
                _mint(
                    settings.mintFeeBeneficiary, 
                    poolId, 
                    amountLpTokensToMintAsFee,
                    ""
                );
            }

            // updating pool        
            totalCerUsdBalance = totalCerUsdBalance + amountCerUsdIn - amountCerUsdToBurn;
            pools[poolId].balanceToken = 
                pools[poolId].balanceToken + uint128(amountTokensIn) - uint128(amountTokensOut);
            pools[poolId].balanceCerUsd = 
                pools[poolId].balanceCerUsd + uint128(amountCerUsdIn) - uint128(amountCerUsdToBurn);
            pools[poolId].lastSqrtKValue = 
                uint128(sqrt(uint(pools[poolId].balanceToken) * 
                    uint(pools[poolId].balanceCerUsd)));

            // burning LP tokens from sender (without approval)
            _burn(msg.sender, poolId, amountLpTokensBalanceToBurn);

            // burning cerUSD
            ICerbyTokenMinterBurner(cerUsdToken).burnHumanAddress(address(this), amountCerUsdToBurn);
        }
        

        // transfering tokens
        _safeTransferHelper(token, transferTo, amountTokensOut, true);
        uint newTokenBalance = _getTokenBalance(token);
        if (
            newTokenBalance + amountTokensOut != oldTokenBalance
        ) {
            revert CerbySwapV1_FeeOnTransferTokensArentSupported();
        }

        emit LiquidityRemoved(
            token, 
            amountTokensOut, 
            amountCerUsdToBurn, 
            amountLpTokensBalanceToBurn
        );

        emit Sync(
            token, 
            pools[poolId].balanceToken, 
            pools[poolId].balanceCerUsd,
            pools[poolId].creditCerUsd
        );

        return amountTokensOut;
    }

    function syncTokenBalanceInPool(address token)
        public
        tokenMustExistInPool(token)
        // checkForBotsAndExecuteCronJobs(msg.sender) // TODO: enable on production
    {
        uint poolId = tokenToPoolId[token];
        pools[poolId].balanceToken = uint128(_getTokenBalance(token));
        
        uint newTotalCerUsdBalance = _getTokenBalance(cerUsdToken);
        pools[poolId].balanceCerUsd = 
            uint128(uint(pools[poolId].balanceCerUsd) + newTotalCerUsdBalance - totalCerUsdBalance);
        pools[poolId].creditCerUsd = 
            pools[poolId].creditCerUsd + newTotalCerUsdBalance - totalCerUsdBalance;

        totalCerUsdBalance = newTotalCerUsdBalance;

        emit Sync(
            token, 
            pools[poolId].balanceToken, 
            pools[poolId].balanceCerUsd,
            pools[poolId].creditCerUsd
        );
    }

    function skimPool(address token)
        public
        tokenMustExistInPool(token)
        // checkForBotsAndExecuteCronJobs(msg.sender) // TODO: enable on production
    {
        uint poolId = tokenToPoolId[token];
        uint newBalanceToken = _getTokenBalance(token);
        uint newBalanceCerUsd = _getTokenBalance(cerUsdToken);

        uint diffBalanceToken = newBalanceToken - pools[poolId].balanceToken;
        if (diffBalanceToken > 0) {
            _safeTransferHelper(token, msg.sender, diffBalanceToken, false);
        }

        uint diffBalanceCerUsd = newBalanceCerUsd - pools[poolId].balanceCerUsd;
        if (diffBalanceCerUsd > 0) {
            _safeTransferHelper(cerUsdToken, msg.sender, diffBalanceCerUsd, false);
        }
    }

    function _getMintFeeLiquidityAmount(uint lastSqrtKValue, uint newSqrtKValue, uint totalLPSupply)
        private
        view
        returns (uint)
    {
        uint amountLpTokensToMintAsFee;
        uint mintFeeMultiplier = settings.mintFeeMultiplier;
        if (
            newSqrtKValue > lastSqrtKValue && 
            lastSqrtKValue > 0 &&
            mintFeeMultiplier > 0
        ) {
            amountLpTokensToMintAsFee = 
                (totalLPSupply * mintFeeMultiplier  * (newSqrtKValue - lastSqrtKValue)) / 
                    (newSqrtKValue * (MINT_FEE_DENORM - mintFeeMultiplier) + 
                        lastSqrtKValue * mintFeeMultiplier);
        }

        return amountLpTokensToMintAsFee;
    }
}