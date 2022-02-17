// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface ICerbySwapV1_Vault {

    function initialize(
        address _token
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

    function withdrawTokens(
        address _token,
        address _to,
        uint256 _value
    )
        external;
}
