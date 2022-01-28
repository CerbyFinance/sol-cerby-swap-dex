// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IUniswapV2Pair {
    
    function sync()
        external;
        
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
        
    function mint(address to) 
        external
        returns (uint);
    
    function burn(address to) 
        external 
        returns (uint amount0, uint amount1);
    
    function swap(
        uint amount0Out, 
        uint amount1Out, 
        address to, 
        bytes calldata data
    ) 
        external;
    
    
    function skim(address to) 
        external;
}
