// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.11;

import "./interfaces/IERC20.sol";
import "./CerbySwapV1_Declarations.sol";
import "./CerbySwapV1_EventsAndErrors.sol";

abstract contract CerbySwapV1_SafeFunctions is
    CerbySwapV1_EventsAndErrors,
    CerbySwapV1_Declarations
{
    function _getTokenBalance(address token)
        internal
        view
        returns (uint balanceToken)
    {
        if (token == nativeToken) {
            // getting native token balance
            balanceToken = address(this).balance;
        } else {
            // getting contract token balance
            balanceToken = IERC20(token).balanceOf(address(this));
        }

        return balanceToken;
    }

    function _safeTransferFromHelper(
        address token,
        address from,
        uint amountTokensIn
    )
        internal
    {
        if (token == nativeToken)  {
            // sender must sent some native tokens
            if (
                msg.value < amountTokensIn
            ) {
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

            return;
        }
        // sender must not send any native tokens
        if (msg.value > 0) {
            revert("G"); // TODO: remove this line on production
            revert CerbySwapV1_MsgValueProvidedMustBeZero();
        }

        // _safeCoreTransferFrom does not require return value
        _safeCoreTransferFrom(
            token,
            from,
            address(this),
            amountTokensIn
        );
    }

    function _safeTransferHelper(
        address token,
        address to,
        uint amountTokensOut,
        bool needToCheckForBots
    )
        internal
    {
        // some transfer such as refund excess of native tokens
        // we don't check for bots
        if (needToCheckForBots) {
            //checkTransactionForBots(token, msg.sender, to); // TODO: enable on production
        }

        if (to == address(this)) return;

        // we trust cerUsdToken and nativeTokens
        // thats why don't need to check whether it has fee-on-transfer
        // these tokens are known to be without any fee-on-transfer
        uint oldBalanceToken;

        if (
            token != cerUsdToken &&
            token != nativeToken
        ) {
            oldBalanceToken = _getTokenBalance(token);
        }

        // actually transferring the tokens
        token == nativeToken)
            ? _safeCoreTransferNative(to, amountTokensOut);
            : _safeCoreTransferToken(token, to, amountTokensOut);

        // we trust cerUsdToken and nativeTokens
        // thats why don't need to check whether it has fee-on-transfer
        // these tokens are known to be without any fee-on-transfer

        if (token == cerUsdToken || token == nativeToken) return;

        uint newBalanceToken = _getTokenBalance(token);
        if (newBalanceToken + amountTokensOut == oldBalanceToken) return;
        revert CerbySwapV1_FeeOnTransferTokensArentSupported();
    }

    function _safeCoreTransferToken(
        address token,
        address to,
        uint value
    ) internal {
        // 0xa9059cbb = bytes4(keccak256(bytes('transfer(address,uint)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0xa9059cbb, to, value));

        // we allow successfull calls and with (true) or without return data
        if (
            ! (success && (data.length == 0 || abi.decode(data, (bool))))
        ) {
            revert CerbySwapV1_SafeTransferTokensFailed();
        }
    }

    function _safeCoreTransferFrom(
        address token,
        address from,
        address to,
        uint value
    ) internal {
        // 0x23b872dd = bytes4(keccak256(bytes('transferFrom(address,address,uint)')));
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));

        // we allow successfull calls and with (true) or without return data
        if (
            ! (success && (data.length == 0 || abi.decode(data, (bool))))
        ) {
            revert CerbySwapV1_SafeTransferFromFailed();
        }
    }

    function _safeCoreTransferNative(address to, uint value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));

        // we allow only successfull calls
        if (
            !success
        ) {
            revert CerbySwapV1_SafeTransferNativeFailed();
        }
    }
}
