// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface ICerbySwapV1_VaultImplementation {

    function initialize(
        address _token,
        address _cerUsdToken, // TODO: remove cerUsd update from here on production
        bool isNativeToken
    )
        external;

    function balanceOf(
        address _account
    )
        external
        view
        returns (uint256);

    function approve(
        address _spender,
        uint256 _value
    )
        external
        returns (bool success);

    function withdrawEth(
        address _to,
        uint256 _value
    )
        external;
}
