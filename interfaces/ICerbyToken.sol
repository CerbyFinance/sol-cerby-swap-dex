// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

struct AccessSettings {
        bool isMinter;
        bool isBurner;
        bool isTransferer;
        bool isModerator;
        bool isTaxer;
        
        address addr;
    }

interface ICerbyToken {
    
    function allowance(
        address owner, 
        address spender
    ) external view returns (uint);
    
    function transferFrom(
        address sender, 
        address recipient, 
        uint256 amount
    ) external returns (bool);
    
    function transfer(
        address recipient, 
        uint256 amount
    ) external returns (bool);
    
    function approve(
        address _spender,
        uint _value
    )  external returns (
        bool success
    );
    
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

    function mintByBridge(address to, uint realAmountToMint) external;

    function burnByBridge(address from, uint realAmountBurn) external;
    
    function getUtilsContractAtPos(uint pos)
        external
        view
        returns (address);
    
    function updateUtilsContracts(AccessSettings[] calldata accessSettings)
        external;
    
    function transferCustom(address sender, address recipient, uint256 amount)
        external;
}