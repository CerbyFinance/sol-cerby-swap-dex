// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.11;

import "./CerbySwapV1_Declarations.sol";

abstract contract CerbySwapV1_Modifiers is CerbySwapV1_Declarations {

    modifier tokenMustExistInPool(
        address _token
    ) {
        if (tokenToPoolId[_token] == 0 || _token == cerUsdToken) {
            revert("C"); // TODO: remove this line on production // C: concern
            revert CerbySwapV1_TokenDoesNotExist();
        }
        _;
    }

    modifier tokenDoesNotExistInPool(
        address _token
    ) { // Q3: used only once
        if (tokenToPoolId[_token] > 0) {
            revert CerbySwapV1_TokenAlreadyExists(); // Q3: is this tested?
        }
        _;
    }

    modifier transactionIsNotExpired(
        uint256 _expireTimestamp
    ) {
        if (block.timestamp > _expireTimestamp) {
            revert("D"); // TODO: remove this line on production // C: concern
            revert CerbySwapV1_TransactionIsExpired();
        }
        _;
    }
}
