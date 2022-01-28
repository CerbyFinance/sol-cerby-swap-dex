// SPDX-License-Identifier: BSD-2-Clause

pragma solidity ^0.8.7;

interface IDefiFactoryToken {
    
    function balanceOf(
        address account
    )
        external
        view
        returns (uint);
    
    function totalSupply()
        external
        view
        returns (uint);
        
    function mintHumanAddress(address to, uint desiredAmountToMint) external;

    function burnHumanAddress(address from, uint desiredAmountToBurn) external;
    
    function transferCustom(address sender, address recipient, uint256 amount) external;
    
    function getUtilsContractAtPos(uint pos)
        external
        view
        returns (address);
}