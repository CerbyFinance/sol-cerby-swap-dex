// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.11;

import "./CerbySwapV1_Declarations_CerUsd.sol";
import "./interfaces/IERC20.sol";

contract CerbySwapV1_Vault is CerbySwapV1_Declarations_CerUsd {
    address token;
    address owner;

    error CerbySwapV1_Vault_SafeTransferNativeFailed();
    error CerbySwapV1_Vault_CallerIsNotOwner();

    constructor(
        address _token,
        address _cerUsd, // TODO: remove cerUsd update from here on production
        bool isNativeToken
    ) {
        if (!isNativeToken) {
            IERC20(_token).approve(msg.sender, type(uint256).max);
        }

        IERC20(_cerUsd).approve(msg.sender, type(uint256).max);

        token = _token;
        cerUsdToken = _cerUsd;
        owner = msg.sender;
    }

    receive() external payable {}

    function token0() external view returns (address) {
        return token;
    }

    function token1() external view returns (address) {
        return cerUsdToken;
    }

    function withdrawEth(address _to, uint256 _value) external {
        if (msg.sender != owner) {
            revert CerbySwapV1_Vault_CallerIsNotOwner();
        }

        // refer to https://github.com/Uniswap/solidity-lib/blob/master/contracts/libraries/TransferHelper.sol
        (bool success, ) = _to.call{value: _value}(new bytes(0));

        // we allow only successfull calls
        if (!success) {
            revert CerbySwapV1_Vault_SafeTransferNativeFailed();
        }
    }
}
