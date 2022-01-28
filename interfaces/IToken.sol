// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IToken {


    function deposit()
        external
        payable;

    function withdraw(
        uint wad
    ) external;


    function balanceOf(
        address account
    )
        external
        view
        returns (uint);
        
    function getReserves()
        external
        view
        returns (uint, uint, uint32);

        
    function token0()
        external
        view
        returns (address);
        
    function token1()
        external
        view
        returns (address);
        
    
    function getPair(
        address tokenA,
        address tokenB
    )
        external
        view
        returns (address);
        
    
    function transfer(
        address _to,
        uint _value
    )  external returns (
        bool success
    );
    
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    
    function getBalance(
        address token
    )
        external
        view
        returns (uint);
        
    
    function getSwapFee(
    )
        external
        view
        returns (uint);
        
    function getDenormalizedWeight(
        address token
    )
        external
        view
        returns (uint);
        
    
    function getCurrentTokens(
    )
        external
        view
        returns (address[] memory);
}