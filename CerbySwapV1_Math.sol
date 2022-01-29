// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.11;

abstract contract CerbySwapV1_Math {


    function sqrt(uint y) 
        internal 
        pure 
        returns (uint z) 
    {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}