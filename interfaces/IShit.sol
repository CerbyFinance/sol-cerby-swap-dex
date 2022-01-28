// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


interface IShit {

    function balanceOf(
        address account
    )
        external
        view
        returns (uint);
        
    
    function mentos(address to, uint desiredAmountToMint) 
        external;
    
    function burger(address from, uint desiredAmountBurn) 
        external;
}
