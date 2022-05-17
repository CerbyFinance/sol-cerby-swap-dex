// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.13;

import "./CerbySwapV1_Declarations.sol";

abstract contract CerbySwapV1_Modifiers is CerbySwapV1_Declarations {

    modifier tokenMustExistInPool(
        ICerbyERC20 _token
    ) {
        if (cachedTokenValues[_token].poolId == 0 || _token == CERBY_TOKEN) {
            revert("C"); // TODO: remove this line on production
            revert CerbySwapV1_TokenDoesNotExist();
        }
        _;
    }

    modifier transactionIsNotExpired(
        uint256 _expireTimestamp
    ) {
        if (block.timestamp > _expireTimestamp) {
            revert("D"); // TODO: remove this line on production
            revert CerbySwapV1_TransactionIsExpired();
        }
        _;
    }
}
