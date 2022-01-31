// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface ICerbySwapV1_Vault {
    function balanceOf(address account) external view returns (uint256);

    function approve(address _spender, uint256 _value)
        external
        returns (bool success);

    function withdrawEth(address _to, uint256 _value) external;
}
