// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.11;

import "./interfaces/IERC20.sol";
import "./CerbySwapV1_Declarations.sol";
import "./CerbySwapV1_EventsAndErrors.sol";

abstract contract CerbySwapV1_SafeFunctions is
    CerbySwapV1_EventsAndErrors,
    CerbySwapV1_Declarations
{
    function _getTokenBalance(address token) internal view returns (uint256) {
        uint256 balanceToken;
        if (token == nativeToken) {
            // getting native token balance
            balanceToken = address(this).balance;
            return balanceToken;
        }

        // token != nativeToken clause
        // getting contract token balance
        balanceToken = IERC20(token).balanceOf(address(this));
        return balanceToken;
    }

    function _safeTransferFromHelper(
        address token,
        address from,
        uint256 amountTokensIn
    ) internal {
        if (token == nativeToken) {
            // sender must sent some native tokens
            if (msg.value < amountTokensIn) {
                revert CerbySwapV1_MsgValueProvidedMustBeLargerThanAmountTokensIn();
            }

            // refunding excess of native tokens
            // to make sure msg.value == amountTokensIn
            if (msg.value > amountTokensIn) {
                _safeTransferHelper(
                    nativeToken,
                    msg.sender,
                    msg.value - amountTokensIn,
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

        if (from == address(this)) {
            return;
        }

        // _safeCoreTransferFrom does not require return value
        _safeCoreTransferFrom(token, from, address(this), amountTokensIn);
    }

    function _safeTransferHelper(
        address token,
        address to,
        uint256 amountTokensOut,
        bool needToCheckForBots
    ) internal {
        if (
            to == address(this) || // don't need to transfer to current contract
            amountTokensOut <= 1
        ) {
            return;
        }

        // some transfer such as refund excess of native tokens
        // we don't check for bots
        if (needToCheckForBots) {
            //checkTransactionForBots(token, msg.sender, to); // TODO: enable on production
        }

        // transferring the native tokens and exiting right after
        // because we trust them
        if (token == nativeToken) {
            _safeCoreTransferNative(to, amountTokensOut);
            return;
        }

        // transferring the cerUSD tokens and exiting right after
        // because we trust them
        if (token == cerUsdToken) {
            _safeCoreTransferToken(token, to, amountTokensOut);
            return;
        }

        // token != cerUsdToken && token != nativeToken clause
        // thats why here we only check whether token has fee-on-transfer
        uint256 oldBalanceToken = _getTokenBalance(token);

        // transferring the tokens
        _safeCoreTransferToken(token, to, amountTokensOut);

        // we trust cerUsdToken and nativeTokens
        // thats why don't need to check whether it has fee-on-transfer
        // these tokens are known to be without any fee-on-transfer
        uint256 newBalanceToken = _getTokenBalance(token);
        if (newBalanceToken + amountTokensOut != oldBalanceToken) {
            revert CerbySwapV1_FeeOnTransferTokensArentSupported();
        }
    }

    function _safeCoreTransferToken(
        address token,
        address to,
        uint256 value
    ) internal {
        // refer to https://github.com/Uniswap/solidity-lib/blob/master/contracts/libraries/TransferHelper.sol
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );

        // we allow successfull calls and with (true) or without return data
        if (!(success && (data.length == 0 || abi.decode(data, (bool))))) {
            revert CerbySwapV1_SafeTransferTokensFailed();
        }
    }

    function _safeCoreTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // refer to https://github.com/Uniswap/solidity-lib/blob/master/contracts/libraries/TransferHelper.sol
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );

        // we allow successfull calls and with (true) or without return data
        if (!(success && (data.length == 0 || abi.decode(data, (bool))))) {
            revert CerbySwapV1_SafeTransferFromFailed();
        }
    }

    function _safeCoreTransferNative(address to, uint256 value) internal {
        // refer to https://github.com/Uniswap/solidity-lib/blob/master/contracts/libraries/TransferHelper.sol
        (bool success, ) = to.call{value: value}(new bytes(0));

        // we allow only successfull calls
        if (!success) {
            revert CerbySwapV1_SafeTransferNativeFailed();
        }
    }
}
