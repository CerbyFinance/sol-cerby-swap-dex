// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ICerbyERC20.sol";

interface ICerbySwapV1_Vault {

    function initialize(
        ICerbyERC20 _token
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
        ICerbyERC20 _token,
        address _to,
        uint256 _value
    )
        external;
}
