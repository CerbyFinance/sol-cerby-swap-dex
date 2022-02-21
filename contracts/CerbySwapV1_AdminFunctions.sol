// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.12;

import "../openzeppelin/access/Ownable.sol";
import "./CerbySwapV1_SwapFunctions.sol";

abstract contract CerbySwapV1_AdminFunctions is
    CerbySwapV1_SwapFunctions,
    Ownable
{
    function adminSetUrlPrefix(
        string calldata _newUrlPrefix
    )
        external
        onlyOwner
    {
        urlPrefix = _newUrlPrefix;
    }

    function adminUpdateNameAndSymbol(
        string memory _newContractName,
        string memory _newContractSymbol
    )
        external
        onlyOwner
    {
        contractName = _newContractName;
        contractSymbol = _newContractSymbol;
    }

    function adminUpdateSettings(
        Settings calldata _settings
    )
        external
        onlyOwner
    {
        if (
            _settings.feeMinimum == 0 ||
            _settings.feeMinimum > _settings.feeMaximum
            // 2.56% is hard limit on updating fee
        ) {
            //revert ("a1"); 
            revert CerbySwapV1_FeeIsWrong();
        }

        if (_settings.tvlMultiplierMinimum > _settings.tvlMultiplierMaximum) {
            //revert ("a2");
            revert CerbySwapV1_TvlMultiplierIsWrong();
        }

        if (_settings.mintFeeMultiplier >= MINT_FEE_DENORM / 2) {
            //revert ("a3");
            revert CerbySwapV1_MintFeeMultiplierMustNotBeLargerThan50Percent();
        }

        settings = _settings;
    }

    // only admins are allowed to create new pools with creditCerUsd = unlimitted
    // this is only for trusted tokens such as ETH, BNB, UNI, etc
    function adminCreatePool(
        address _token,
        uint256 _amountTokensIn,
        uint256 _amountCerUsdToMint,
        address _transferTo
    )
        external
        payable
        onlyOwner
    {
        _createPool(
            _token,
            _amountTokensIn,
            _amountCerUsdToMint,
            MAX_CER_USD_CREDIT, // creditCerUsd
            _transferTo
        );
    }

    // admin can change cerUsd credit in the pool
    // just in case user adds a token with too high price
    // admins will be able to fix it by increasing credit
    // and swapping extra tokens + adding back to liquidity
    // using external contract assigned with admin role
    function adminChangeCerUsdCreditInPool(
        address _token,
        uint256 _amountCerUsdCredit
    )
        external
        onlyOwner
        tokenMustExistInPool(_token)
    {
        PoolBalances memory poolBalances = _getPoolBalances(
            _token
        );

        // getting pool storage link (saves gas compared to memory)
        Pool storage pool = pools[cachedTokenValues[_token].poolId];

        // changing credit for user-created pool
        pool.creditCerUsd = uint128(
            _amountCerUsdCredit
        );

        // Sync event to update pool variables in the graph node
        emit Sync(
            _token,
            poolBalances.balanceToken,
            poolBalances.balanceCerUsd,
            _amountCerUsdCredit
        );
    }
}
