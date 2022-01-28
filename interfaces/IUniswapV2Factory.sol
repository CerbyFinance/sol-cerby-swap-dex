// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IUniswapV2Factory {
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
  
    function getPair(
        address tokenA,
        address tokenB
    )
        external
        view
        returns (address);
        
    function createPair(
        address tokenA,
        address tokenB
    ) 
        external
        returns (address);
        
}
