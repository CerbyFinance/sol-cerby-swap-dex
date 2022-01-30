// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.11;

import "./interfaces/ICerbyTokenMinterBurner.sol";
import "./CerbySwapV1_Modifiers.sol";
import "./CerbySwapV1_Math.sol";
import "./CerbySwapV1_SafeFunctions.sol";
import "./CerbySwapV1_ERC1155.sol";

abstract contract CerbySwapV1_LiquidityFunctions is
    CerbySwapV1_SafeFunctions,
    CerbySwapV1_Modifiers,
    CerbySwapV1_Math,
    CerbySwapV1_ERC1155
{
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
        emit Sync(
            _token,
            pool.balanceToken,
            pool.balanceCerUsd,
            pool.creditCerUsd
        );
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
            uint128(amountTokensIn),
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
        emit Sync(
            token,
            pool.balanceToken,
            pool.balanceCerUsd,
            pool.creditCerUsd
        );
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

        // safely transferring tokens from sender to this contract
        // or doing nothing if msg.value specified correctly
        _safeTransferFromHelper(token, msg.sender, amountTokensIn);

        // finding out how many tokens we've actually received
        uint256 newBalanceToken = _getTokenBalance(token);
        amountTokensIn = newBalanceToken - pool.balanceToken;
        if (amountTokensIn <= 1) {
            revert("F"); // TODO: remove this line on production
            revert CerbySwapV1_AmountOfTokensMustBeLargerThanOne();
        }

        // finding out if for some reason we've received cerUSD tokens as well
        uint256 newTotalCerUsdBalance = _getTokenBalance(cerUsdToken);
        uint256 amountCerUsdIn = newTotalCerUsdBalance - totalCerUsdBalance;

        {
            // calculating new sqrt(k) value before updating pool
            uint256 newSqrtKValue = sqrt(
                uint256(pool.balanceToken) * uint256(pool.balanceCerUsd)
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
            pool.balanceToken;
        _mint(transferTo, poolId, lpAmount, "");

        {
            // scope to avoid stack to deep error
            // calculating amount of cerUSD to mint according to current price
            uint256 amountCerUsdToMint = (amountTokensIn *
                uint256(pool.balanceCerUsd)) / uint256(pool.balanceToken);
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
            pool.balanceToken = pool.balanceToken + uint128(amountTokensIn);
            pool.balanceCerUsd =
                pool.balanceCerUsd +
                uint128(amountCerUsdIn + amountCerUsdToMint);
            pool.lastSqrtKValue = uint128(
                sqrt(uint256(pool.balanceToken) * uint256(pool.balanceCerUsd))
            );

            // LiquidityAdded event is needed to post in telegram channel
            emit LiquidityAdded(
                token,
                amountTokensIn,
                amountCerUsdToMint,
                lpAmount
            );

            // Sync event to update pool variables in the graph node
            emit Sync(
                token,
                pool.balanceToken,
                pool.balanceCerUsd,
                pool.creditCerUsd
            );
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

        // finding out if for some reason we've received tokens
        uint256 oldBalanceToken = _getTokenBalance(token);
        uint256 amountTokensIn = oldBalanceToken - pool.balanceToken;

        // finding out if for some reason we've received cerUSD tokens as well
        uint256 amountCerUsdIn = _getTokenBalance(cerUsdToken) -
            totalCerUsdBalance;

        // calculating amount of tokens to transfer
        uint256 totalLPSupply = contractTotalSupply[poolId];
        uint256 amountTokensOut = (uint256(pool.balanceToken) *
            amountLpTokensBalanceToBurn) / totalLPSupply;

        // calculating amount of cerUSD to burn
        uint256 amountCerUsdToBurn = (uint256(pool.balanceCerUsd) *
            amountLpTokensBalanceToBurn) / totalLPSupply;

        {
            // scope to avoid stack too deep error
            // storing sqrt(k) value before updating pool
            uint256 newSqrtKValue = sqrt(
                uint256(pool.balanceToken) * uint256(pool.balanceCerUsd)
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
            pool.balanceToken =
                pool.balanceToken +
                uint128(amountTokensIn) -
                uint128(amountTokensOut);
            pool.balanceCerUsd =
                pool.balanceCerUsd +
                uint128(amountCerUsdIn) -
                uint128(amountCerUsdToBurn);
            pool.lastSqrtKValue = uint128(
                sqrt(uint256(pool.balanceToken) * uint256(pool.balanceCerUsd))
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
