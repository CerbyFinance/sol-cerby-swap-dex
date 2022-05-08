// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.13;

import "./interfaces/IBasicERC20.sol";

contract CerbySwapV1_Vault {

    address token; // TODO: IERC20
    address constant CER_USD_TOKEN = 0x3B69b8C5c6a4c8c2a90dc93F3B0238BF70cC9640; // TODO: IERC20
    address constant factory = 0xfAf360f184788b00623828165405D7F52820D789;

    error CerbySwapV1_Vault_SafeTransferNativeFailed();
    error CerbySwapV1_Vault_CallerIsNotFactory();
    error CerbySwapV1_Vault_AlreadyInitialized();
    error CerbySwapV1_Vault_SafeTransferFailed();

    receive() external payable {}

    modifier onlyFactory {
        if (msg.sender != factory) {
            revert CerbySwapV1_Vault_CallerIsNotFactory();
        }
        _;
    }

    function initialize(
        address _token
    )
        external
    {
        // initialize contract only once
        if (token != address(0)) {
            revert CerbySwapV1_Vault_AlreadyInitialized();
        }

        token = _token;
    }

    function withdrawEth(
        address _to,
        uint256 _value
    )
        external
        onlyFactory
    {
        // refer to https://github.com/Uniswap/solidity-lib/blob/master/contracts/libraries/TransferHelper.sol
        (bool success, ) = _to.call{value: _value}(new bytes(0));

        // we allow only successfull calls
        if (!success) {
            revert CerbySwapV1_Vault_SafeTransferNativeFailed();
        }
    }

    function withdrawTokens(
        address _token,
        address _to,
        uint256 _value
    )
        external
        onlyFactory
    {
        // refer to https://github.com/Uniswap/solidity-lib/blob/master/contracts/libraries/TransferHelper.sol
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(0xa9059cbb, _to, _value));
        
        // we allow successfull calls with (true) or without return data
        if (!(success && (data.length == 0 || abi.decode(data, (bool))))) {
            revert CerbySwapV1_Vault_SafeTransferFailed();
        }
    }

    function token0()
        external
        view
        returns (address)
    {
        return token;
    }

    function token1()
        external
        pure
        returns (address)
    {
        return CER_USD_TOKEN;
    }
}
