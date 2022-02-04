// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.11;

import "./interfaces/IERC20.sol";

contract CerbySwapV1_VaultImplementation {

    address token;
    address cerUsdToken;
    address owner; // Q: would this mean owner is always the same?

    error CerbySwapV1_Vault_SafeTransferNativeFailed();
    error CerbySwapV1_Vault_CallerIsNotOwner();
    error CerbySwapV1_Vault_AlreadyInitialized();

    constructor() {} // Q: why?

    function initialize(
        address _token,
        address _cerUsdToken, // TODO: remove cerUsd update from here on production
        bool _isNativeToken
    )
        external
    {
        if (owner != address(0)) {
            revert CerbySwapV1_Vault_AlreadyInitialized();
        }

        if (_isNativeToken == false) {
            IERC20(_token).approve( // re-entrancy problem
                msg.sender,
                type(uint256).max
            );
        }

        IERC20(_cerUsdToken).approve(
            msg.sender,
            type(uint256).max
        );

        token = _token;
        cerUsdToken = _cerUsdToken;
        owner = msg.sender; // Q: this address is main contract then?
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
        if (msg.sender != owner) { // Q: who will be calling?
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
