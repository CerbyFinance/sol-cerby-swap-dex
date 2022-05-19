// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.14;

import "./interfaces/ICerbyERC20.sol";
import "./interfaces/ICerbySwapV1_Vault.sol";
import "./CerbySwapV1_MinimalProxy.sol";

abstract contract CerbySwapV1_SafeFunctions is CerbySwapV1_MinimalProxy
{
    function getPoolBalancesByToken(
        ICerbyERC20 _token
    )
        external
        view
        returns (PoolBalances memory)
    {
        return _getPoolBalances(_token);
    }

    function _getPoolBalances(
        ICerbyERC20 _token
    )
        internal
        view
        returns (PoolBalances memory)
    {
        ICerbySwapV1_Vault vault = 
            address(cachedTokenValues[_token].vaultAddress) == address(0) ? 
                _generateVaultAddressByToken(_token) :
                cachedTokenValues[_token].vaultAddress;

        return PoolBalances(
            _getTokenBalance(_token, vault),
            _getTokenBalance(CERBY_TOKEN, vault)
        );
    }

    function _getTokenBalance(
        ICerbyERC20 _token,
        ICerbySwapV1_Vault _vault
    )
        internal
        view
        returns (uint256)
    {
        return _token == NATIVE_TOKEN ? address(_vault).balance :
            _token.balanceOf(address(_vault));
    }

    function _safeTransferFromHelper(
        ICerbyERC20 _token,
        address _from,
        address _to,
        uint256 _amountTokens
    )
        internal
    {
        if (_amountTokens == 0) return;

        if (_from == msg.sender) {
            if (_token != NATIVE_TOKEN) {
                // transferring tokens from user to vault
                _safeCoreTransferFrom(
                    _token,
                    _from,
                    _to,
                    _amountTokens
                );

                return; // early exit for non-native tokens as they are having larger volume
            }

            // transferring native token from user to vault
            uint256 nativeBalance = address(this).balance;

            // refunding excess of native tokens
            // to make sure nativeBalance == amountTokensIn
            if (nativeBalance > _amountTokens) {
                _safeCoreTransferNative(
                    msg.sender,
                    nativeBalance - _amountTokens
                );
            }

            _safeCoreTransferNative(
                _to,
                _amountTokens
            );
            return;
        }

        // transferring tokens from vault to user
        if (_token != NATIVE_TOKEN) {
            ICerbySwapV1_Vault(_from).withdrawTokens(
                _token,
                _to,
                _amountTokens
            );
            return; // early exit for non-native tokens as they are having larger volume
        }

        // transferring native token from vault to user
        ICerbySwapV1_Vault(_from).withdrawEth(
            _to,
            _amountTokens
        );
    }

    function _safeCoreTransferFrom(
        ICerbyERC20 _token,
        address _from,
        address _to,
        uint256 _value
    )
        internal
    {
        // refer to https://github.com/Uniswap/solidity-lib/blob/c01640b0f0f1d8a85cba8de378cc48469fcfd9a6/contracts/libraries/TransferHelper.sol#L33-L45
        (bool success, bytes memory data) = address(_token).call(
            abi.encodeWithSelector(
                0x23b872dd, // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
                _from,
                _to,
                _value
            )
        );

        // we allow successfull calls and with (true) or without return data
        if (!(success && (data.length == 0 || abi.decode(data, (bool))))) {
            revert("x1");
            revert CerbySwapV1_SafeTransferFromFailed();
        }
    }

    function _safeCoreTransferNative(
        address _to,
        uint256 _value
    )
        internal
    {
        // refer to https://github.com/Uniswap/solidity-lib/blob/c01640b0f0f1d8a85cba8de378cc48469fcfd9a6/contracts/libraries/TransferHelper.sol#L47-L50
        (bool success, ) = _to.call{value: _value}(new bytes(0));

        // we allow only successfull calls
        if (!success) {
            revert("x2");
            revert CerbySwapV1_SafeTransferNativeFailed();
        }
    }
}
