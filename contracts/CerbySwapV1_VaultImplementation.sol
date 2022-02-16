// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.11;

import "./interfaces/IBasicERC20.sol";

contract CerbySwapV1_VaultImplementation { // Q2: consider renaming to just CerbySwapV1_Vault

    address token;
    address cerUsdToken; // TODO: make constant on production
    address factory; // TODO: make constant on production // could rename to factory

    error CerbySwapV1_Vault_SafeTransferNativeFailed();
    error CerbySwapV1_Vault_CallerIsNotOwner();
    error CerbySwapV1_Vault_AlreadyInitialized(); // TODO: remove on production // C: concern

    function initialize(
        address _token,
        address _cerUsdToken, // TODO: remove on production
        bool _isNativeToken
    )
        external
        //onlyOwner // TODO: make onlyOwner here because factory will be predefined in the constant on production
    {
        // initialize contract only once
        if (factory != address(0)) { // TODO: remove on production // C: concern
            revert CerbySwapV1_Vault_AlreadyInitialized();
        }

        token = _token;
        cerUsdToken = _cerUsdToken; // TODO: remove on production
        factory = msg.sender; // TODO: remove on production

        // Q3: is this really needed?
        // (who is being approved and why)
        IBasicERC20(_cerUsdToken).approve(
            factory,
            type(uint256).max
        );

        // Q3: is this really needed?
        // (who is being approved and why)
        if (!_isNativeToken) {
            IBasicERC20(_token).approve(
                factory,
                type(uint256).max
            );
        }
    }

    receive() external payable {}

    function token0()
        external
        view
        returns (address)
    {
        return token;
    }

    function token1()
        external
        view
        returns (address)
    {
        return cerUsdToken;
    }

    function withdrawEth(
        address _to,
        uint256 _value
    )
        external
    {
        if (owner != msg.sender) {
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
