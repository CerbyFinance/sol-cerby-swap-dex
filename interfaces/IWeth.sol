// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IWeth {

    function balanceOf(
        address account
    )
        external
        view
        returns (uint);

    function transfer(
        address _to,
        uint _value
    )  external returns (
        bool success
    );
        
    function deposit()
        external
        payable;

    function withdraw(
        uint wad
    ) external;

    function approve(
        address _spender,
        uint _value
    )  external returns (
        bool success
    );
}
