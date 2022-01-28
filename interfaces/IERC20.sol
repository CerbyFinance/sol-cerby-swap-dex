// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;


interface IERC20 {

    function balanceOf(
        address account
    )
        external
        view
        returns (uint);
}