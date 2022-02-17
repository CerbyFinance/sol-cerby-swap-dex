// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.12;

abstract contract CerbySwapV1_Math {

    function sqrt(
        uint256 _y
    )
        internal
        pure
        returns (uint256 z)
    {
        if (_y > 3) {
            z = _y;
            uint256 x = _y / 2 + 1;
            while (x < z) {
                z = x;
                x = (_y / x + x) / 2;
            }
        } else if (_y != 0) {
            z = 1;
        }
    }
}
