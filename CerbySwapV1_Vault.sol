// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.11;

import "./CerbySwapV1_Declarations_CerUsd.sol";
import "./interfaces/IERC20.sol";

contract CerbySwapV1_Vault is CerbySwapV1_Declarations_CerUsd {
    address token;

    constructor(address _token) {
        IERC20(_token).approve(msg.sender, type(uint256).max);

        token = _token;
    }

    function token0() external view returns (address) {
        return token;
    }

    function token1() external view returns (address) {
        return cerUsdToken;
    }
}
