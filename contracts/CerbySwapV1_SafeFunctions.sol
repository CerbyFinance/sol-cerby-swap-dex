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
        if (NATIVE_TOKEN == _token) {
            return PoolBalances(
                address(this).balance,
                _getTokenBalance(CERBY_TOKEN, ICerbySwapV1_Vault(address(this)))
            );
        }

        // non-native token
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
        // if for some reason we need to transfer nothing => just return without fail
        if (_amountTokens == 0) return;

        /* 
        Only these transfer scenarios possible:
            1) user --> vault, where vault = this contract (only for native token pool)
                1.1) cerby tokens
                1.2) native tokens
            2) user --> vault, where vault != this contract (for non-native token pools)
                2.1) cerby tokens
                2.2) other tokens
            3) vault --> user, where vault = this contract (only for native token pool)
                3.1) cerby tokens
                3.2) native tokens
            4) vault --> user, where vault != this contract (for non-native token pools)
                4.3) cerby tokens
                4.4) other tokens
            5) vaultA --> vault, where vault = this contract (only for native token pool)
                5.1) cerby tokens
            6) vault --> vaultA, where vault = this contract (only for native token pool)
                6.1) cerby tokens
        */


        // 1) native token transfer from user to vault (or this contract)
        if (_to == address(this)) {

            // 5) 5.1) transferring cerby tokens from vaultA to vault (or this contract)
            if (msg.sender != _from && _token == CERBY_TOKEN) {
                ICerbySwapV1_Vault(_from).withdrawTokens(
                    _token,
                    _to,
                    _amountTokens
                );
                return;
            }

            // 1.1) transferring cerby token from user to this contract
            if (_token == CERBY_TOKEN /* && msg.sender == _from */) {
                // using regular transferFrom because it is known token that returns true
                CERBY_TOKEN.transferFrom(
                    _from,
                    _to,
                    _amountTokens
                );
                return;
            }

            // 1.2) native token transferFrom
            // if for some reason user sent us less eth than needed
            // we are throwing an error
            if (msg.value < _amountTokens) {
                revert("x2"); // TODO: remove on production
                revert CerbySwapV1_MsgValueMustBeLargerOrEqualToAmountTokensIn();
            }

            // refunding excess of native tokens
            // to make sure user sent exact _amountTokens we need
            if (msg.value > _amountTokens) {
                _safeCoreTransferNative(
                    msg.sender,
                    msg.value - _amountTokens
                );
            }


            // we don't transfer native token to the vault because
            // vault is current contract for native tokens
            return;
        }

        // 3) token transfer from vault (or this contract) to user
        if (_from == address(this)) {

            // 3.1) 6) 6.1) transferring CERBY token from this contract to user (or vault)
            if (_token == CERBY_TOKEN) {
                // using regular transfer because it is known token that returns true
                CERBY_TOKEN.transfer(
                    _to,
                    _amountTokens
                );
                return;
            }

            // 3.2) native token transfer from this contract to user
            _safeCoreTransferNative(
                _to,
                _amountTokens
            );
            return;
        }

        // 2) transferring tokens (incl. CERBY) from user to vault
        if (_from == msg.sender) {
            // 2.1) transferring cerby token from user to vault
            if (_token == CERBY_TOKEN) {
                // using regular transferFrom because it is known token that returns true
                CERBY_TOKEN.transferFrom(
                    _from,
                    _to,
                    _amountTokens
                );
                return;
            }

            // 2.2) transferring other token from user to vault
            _safeCoreTransferFrom(
                _token,
                _from,
                _to,
                _amountTokens
            );
            return; 
        }

        // 4) 4.1) 4.2) transferring tokens (incl. CERBY) from vault to user
        // no other possible case available here
        ICerbySwapV1_Vault(_from).withdrawTokens(
            _token,
            _to,
            _amountTokens
        );
        return;
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
