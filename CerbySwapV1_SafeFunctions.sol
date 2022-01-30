// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.11;

import "./interfaces/IERC20.sol";
import "./CerbySwapV1_Declarations.sol";
import "./CerbySwapV1_EventsAndErrors.sol";

abstract contract CerbySwapV1_SafeFunctions is
    CerbySwapV1_EventsAndErrors,
    CerbySwapV1_Declarations
{
    function _getPoolBalances(address _token)
        internal
        view
        returns(PoolBalances memory)
    {
        return PoolBalances(
            _getTokenBalance(_token),
            _getTokenBalance(cerUsdToken)
        );
    }

    function _getTokenBalance(address _token) internal view returns (uint256) {
        uint256 balanceToken;
        if (_token == nativeToken) {
            // getting native token balance
            balanceToken = address(this).balance;
            return balanceToken;
        }

        // token != nativeToken clause
        // getting contract token balance
        balanceToken = IERC20(_token).balanceOf(address(this));
        return balanceToken;
    }

    function _safeTransferFromHelper(
        address _token,
        address _from,
        uint256 _amountTokensIn
    ) internal {
        if (_token == nativeToken) {
            // sender must sent some native tokens
            if (msg.value < _amountTokensIn) {
                revert CerbySwapV1_MsgValueProvidedMustBeLargerThanAmountTokensIn();
            }

            // refunding excess of native tokens
            // to make sure msg.value == amountTokensIn
            if (msg.value > _amountTokensIn) {
                _safeTransferHelper(
                    nativeToken,
                    msg.sender,
                    msg.value - _amountTokensIn,
                    false
                );
            }

            // msg.value == amountTokensIn here
            return;
        }

        // token != nativeToken clause
        // sender must not send any native tokens
        if (msg.value > 0) {
            revert("G"); // TODO: remove this line on production
            revert CerbySwapV1_MsgValueProvidedMustBeZero();
        }

        if (_from == address(this)) {
            return;
        }

        // _safeCoreTransferFrom does not require return value
        _safeCoreTransferFrom(_token, _from, address(this), _amountTokensIn);
    }

    function _safeTransferHelper(
        address _token,
        address _to,
        uint256 _amountTokensOut,
        bool _needToCheckForBots
    ) internal {
        if (
            _to == address(this) || // don't need to transfer to current contract
            _amountTokensOut <= 1
        ) {
            return;
        }

        // some transfer such as refund excess of native tokens
        // we don't check for bots
        if (_needToCheckForBots) {
            //checkTransactionForBots(token, msg.sender, to); // TODO: enable on production
        }

        // transferring the native tokens and exiting right after
        // because we trust them
        if (_token == nativeToken) {
            _safeCoreTransferNative(_to, _amountTokensOut);
            return;
        }

        // transferring the cerUSD tokens and exiting right after
        // because we trust them
        if (_token == cerUsdToken) {
            _safeCoreTransferToken(_token, _to, _amountTokensOut);
            return;
        }

        // token != cerUsdToken && token != nativeToken clause
        // thats why here we only check whether token has fee-on-transfer
        uint256 oldBalanceToken = _getTokenBalance(_token);

        // transferring the tokens
        _safeCoreTransferToken(_token, _to, _amountTokensOut);

        // we trust cerUsdToken and nativeTokens
        // thats why don't need to check whether it has fee-on-transfer
        // these tokens are known to be without any fee-on-transfer
        uint256 newBalanceToken = _getTokenBalance(_token);
        if (newBalanceToken + _amountTokensOut != oldBalanceToken) {
            revert CerbySwapV1_FeeOnTransferTokensArentSupported();
        }
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
