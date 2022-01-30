// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.11;

import "./interfaces/IERC20.sol";
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
        // native tokens sender --> this
        if (_token == nativeToken && _to == address(this)) {
            // sender must sent some native tokens
            if (msg.value < _amountTokens) {
                revert CerbySwapV1_MsgValueProvidedMustBeLargerThanAmountTokensIn();
            }

            // refunding excess of native tokens
            // to make sure msg.value == amountTokensIn
            if (msg.value > _amountTokens) {
                _safeCoreTransferNative(msg.sender, msg.value - _amountTokens);
            }

            // msg.value == amountTokensIn here
            return;
        }

        // native tokens this --> sender
        if (
            _token == nativeToken &&
            _from == address(this) &&
            _to != address(this)
        ) {
            _safeCoreTransferNative(_to, _amountTokens);
        }

        // token != nativeToken clause
        // sender must not send any native tokens
        if (msg.value > 0) {
            revert("G"); // TODO: remove this line on production
            revert CerbySwapV1_MsgValueProvidedMustBeZero();
        }

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
