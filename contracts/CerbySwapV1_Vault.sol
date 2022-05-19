// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.14;

import "./interfaces/ICerbyERC20.sol";

contract CerbySwapV1_Vault {

    ICerbyERC20 token;
    ICerbyERC20 constant CERBY_TOKEN = ICerbyERC20(0x3B69b8C5c6a4c8c2a90dc93F3B0238BF70cC9640);
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
        ICerbyERC20 _token
    )
        external
    {
        // initialize contract only once
        if (address(token) != address(0)) {
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
        // refer to https://github.com/Uniswap/solidity-lib/blob/c01640b0f0f1d8a85cba8de378cc48469fcfd9a6/contracts/libraries/TransferHelper.sol#L47-L50
        (bool success, ) = _to.call{value: _value}(new bytes(0));

        // we allow only successfull calls
        if (!success) {
            revert CerbySwapV1_Vault_SafeTransferNativeFailed();
        }
    }

    function withdrawTokens(
        ICerbyERC20 _token,
        address _to,
        uint256 _value
    )
        external
        onlyFactory
    {
        // refer to https://github.com/Uniswap/solidity-lib/blob/c01640b0f0f1d8a85cba8de378cc48469fcfd9a6/contracts/libraries/TransferHelper.sol#L20-L31
        (bool success, bytes memory data) = address(_token).call(abi.encodeWithSelector(0xa9059cbb, _to, _value));
        
        // we allow successfull calls with (true) or without return data
        if (!(success && (data.length == 0 || abi.decode(data, (bool))))) {
            revert CerbySwapV1_Vault_SafeTransferFailed();
        }
    }

    function token0()
        external
        view
        returns (ICerbyERC20)
    {
        return token;
    }

    function token1()
        external
        pure
        returns (ICerbyERC20)
    {
        return CERBY_TOKEN;
    }
}
