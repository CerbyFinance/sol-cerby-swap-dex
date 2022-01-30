// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.11;

import "./CerbySwapV1_Declarations.sol";


abstract contract CerbySwapV1_Modifiers is CerbySwapV1_Declarations {

    modifier tokenMustExistInPool(address token)
    {
        if(
            tokenToPoolId[token] == 0 ||
            token == cerUsdToken
        ){
            revert("C"); // TODO: remove this line on production
            revert CerbySwapV1_TokenDoesNotExist();
        }
        _;
    }

    modifier tokenDoesNotExistInPool(address token)
    {
        if(
            tokenToPoolId[token] > 0
        ) {
            revert CerbySwapV1_TokenAlreadyExists();
        }
        _;
    }

    modifier transactionIsNotExpired(uint expireTimestamp)
    {
        if (
            block.timestamp > expireTimestamp
        ) {
            revert("D"); // TODO: remove this line on production
            revert CerbySwapV1_TransactionIsExpired();
        }
        _;
    }
}
