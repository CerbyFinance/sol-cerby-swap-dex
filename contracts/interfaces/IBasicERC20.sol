// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IBasicERC20 {

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
}
