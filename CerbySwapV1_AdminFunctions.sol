// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.11;

import "./openzeppelin/access/Ownable.sol";
import "./CerbySwapV1_LiquidityFunctions.sol";

abstract contract CerbySwapV1_AdminFunctions is 
    CerbySwapV1_LiquidityFunctions, 
    Ownable 
{
    // TODO: remove on production
    function testSetupTokens(address , address _testCerbyToken, address _cerUsdToken, address _testUsdcToken, address )
        external
    {
        //testCerbyBotDetectionContract = _testCerbyBotDetectionContract;
        testCerbyToken = _testCerbyToken;
        cerUsdToken = _cerUsdToken;
        testUsdcToken = _testUsdcToken;
        
        testInit();
    }

    // TODO: remove on production
    function testInit()
        public
    {
        // TODO: remove on production
        _createPool(
            testCerbyToken,
            1e18 * 1e6,
            1e18 * 5e5,
            type(uint).max,
            msg.sender
        );

        // TODO: remove on production
        _createPool(
            testUsdcToken,
            1e18 * 7e5,
            1e18 * 7e5,
            type(uint).max,
            msg.sender
        );
    }

    // TODO: remove on production
    function adminInitialize() 
        external
        payable
        onlyOwner() // TODO: enable on production
    {        

        // TODO: remove on production
        _createPool(
            nativeToken,
            1e15,
            1e18 * 1e6,
            type(uint).max,
            msg.sender
        );
    }


    function adminSetURI(string calldata newUrlPrefix)
        external
        onlyOwner()
    {
        _setURI(string(abi.encodePacked(newUrlPrefix, "{id}.json")));

        _urlPrefix = newUrlPrefix;
    }

    function adminUpdateNameAndSymbol(string memory newName, string memory newSymbol)
        external
        onlyOwner()
    {
        _name = newName;
        _symbol = newSymbol;
    }

    function adminUpdateFeesAndTvlMultipliers(
        Settings calldata _settings
    )
        external
        onlyOwner()
    {
        if(
            0 == _settings.feeMinimum ||
            _settings.feeMinimum > _settings.feeMaximum ||
            _settings.feeMaximum > 500 // 5.00% is hard limit on updating fee
        ) {
            revert CerbySwapV1_FeeIsWrong();
        }

        if (_settings.tvlMultiplierMinimum > _settings.tvlMultiplierMaximum) {
            revert CerbySwapV1_TvlMultiplierIsWrong();
        }

        if (_settings.mintFeeMultiplier * 2 >= MINT_FEE_DENORM) {
            revert CerbySwapV1_MintFeeMultiplierMustNotBeLargerThan50Percent();
        }

        settings = _settings;
    }


    // only admins are allowed to create new pools with creditCerUsd = unlimitted
    // this is only for trusted tokens such as ETH, BNB, UNI, etc
    function adminCreatePool(
        address token, 
        uint amountTokensIn, 
        uint amountCerUsdToMint, 
        address transferTo
    )
        external
        payable
        onlyOwner()
    {
        _createPool(
            token, 
            amountTokensIn, 
            amountCerUsdToMint, 
            type(uint).max, // creditCerUsd
            transferTo
        );
    }


    // admin can change cerUsd credit in the pool
    // just in case user adds a token with too high price
    // admins will be able to fix it by increasing credit 
    // and swapping extra tokens + adding back to liquidity
    // using external contract assigned with admin role
    function adminChangeCerUsdCreditInPool(
        address token,
        uint amountCerUsdCredit
    )
        external
        onlyOwner()
        tokenMustExistInPool(token)
    {
        // getting pool storage link (saves gas compared to memory)
        Pool storage pool = pools[tokenToPoolId[token]];

        // changing credit for user-created pool
        pool.creditCerUsd = amountCerUsdCredit;
        
        // Sync event to update pool variables in the graph node
        emit Sync(
            token, 
            pool.balanceToken, 
            pool.balanceCerUsd,
            pool.creditCerUsd
        );
    }

}