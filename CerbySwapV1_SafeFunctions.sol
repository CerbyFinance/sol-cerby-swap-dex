// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.11;

import "./interfaces/IERC20.sol";
import "./interfaces/ICerbySwapV1_Vault.sol";
import "./CerbySwapV1_Declarations.sol";
import "./CerbySwapV1_EventsAndErrors.sol";

abstract contract CerbySwapV1_SafeFunctions is
    CerbySwapV1_EventsAndErrors,
    CerbySwapV1_Declarations
{
    function _getPoolBalances(address _token, address _vault)
        internal
        view
        returns (PoolBalances memory)
    {
        return
            PoolBalances(
                _getTokenBalance(_token, _vault),
                _getTokenBalance(cerUsdToken, _vault)
            );
    }

    function _getTokenBalance(address _token, address _vault)
        internal
        view
        returns (uint256)
    {
        uint256 balanceToken;
        if (_token == nativeToken) {
            // getting native token balance
            balanceToken = _vault.balance;
            return balanceToken;
        }

        // token != nativeToken clause
        // getting contract token balance
        balanceToken = IERC20(_token).balanceOf(_vault);
        return balanceToken;
    }

    function _safeTransferFromHelper(
        address _token,
        address _from,
        address _to,
        uint256 _amountTokens
    ) internal {
        if (_amountTokens <= 1 || _from == _to) {
            return;
        }

        // native tokens sender --> vault
        if (_token == nativeToken && _from == msg.sender) {
            // sender must sent some native tokens
            uint256 nativeBalance = address(this).balance;
            if (nativeBalance < _amountTokens) {
                revert("asd");
                revert CerbySwapV1_MsgValueProvidedMustBeLargerThanAmountTokensIn();
            }

            // refunding excess of native tokens
            // to make sure nativeBalance == amountTokensIn
            if (nativeBalance > _amountTokens) {
                _safeCoreTransferNative(
                    msg.sender,
                    nativeBalance - _amountTokens
                );
            }

            _safeCoreTransferNative(_to, _amountTokens);
            return;
        }

        // native tokens vault --> _to
        if (_token == nativeToken && _from != msg.sender) {
            ICerbySwapV1_Vault(_from).withdrawEth(_to, _amountTokens);
            return;
        }

        // token != nativeToken clause
        // _safeCoreTransferFrom does not require return value
        _safeCoreTransferFrom(_token, _from, _to, _amountTokens);
    }

    function _safeCoreTransferToken(
        address _token,
        address _to,
        uint256 _value
    ) internal {
        // refer to https://github.com/Uniswap/solidity-lib/blob/master/contracts/libraries/TransferHelper.sol
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(0xa9059cbb, _to, _value)
        );

        // we allow successfull calls and with (true) or without return data
        if (!(success && (data.length == 0 || abi.decode(data, (bool))))) {
            revert CerbySwapV1_SafeTransferTokensFailed();
        }
    }

    function _safeCoreTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _value
    ) internal {
        // refer to https://github.com/Uniswap/solidity-lib/blob/master/contracts/libraries/TransferHelper.sol
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(0x23b872dd, _from, _to, _value)
        );

        // we allow successfull calls and with (true) or without return data
        if (!(success && (data.length == 0 || abi.decode(data, (bool))))) {
            revert CerbySwapV1_SafeTransferFromFailed();
        }
    }

    function _safeCoreTransferNative(address _to, uint256 _value) internal {
        // refer to https://github.com/Uniswap/solidity-lib/blob/master/contracts/libraries/TransferHelper.sol
        (bool success, ) = _to.call{value: _value}(new bytes(0));

        // we allow only successfull calls
        if (!success) {
            revert CerbySwapV1_SafeTransferNativeFailed();
        }
    }
}
