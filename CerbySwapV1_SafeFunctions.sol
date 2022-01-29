// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.11;

import "./interfaces/IERC20.sol";
import "./CerbySwapV1_Declarations.sol";
import "./CerbySwapV1_EventsAndErrors.sol";

abstract contract CerbySwapV1_SafeFunctions is CerbySwapV1_EventsAndErrors, CerbySwapV1_Declarations {

    function _getTokenBalance(address token)
        internal
        view
        returns (uint balanceToken)
    {
        if (token == nativeToken) {
            balanceToken = address(this).balance;
        } else {
            balanceToken = IERC20(token).balanceOf(address(this));
        }

        return balanceToken;
    }

    function _safeTransferFromHelper(address token, address from, uint amountIn)
        internal
    {
        if (token != nativeToken) {
            // caller must not send any native tokens
            if (
                msg.value > 0
            ) {
                revert("G"); // TODO: remove this line on production
                revert CerbySwapV1_MsgValueProvidedMustBeZero();
            }

            if (from != address(this)) {
                _safeTransferFrom(token, from, address(this), amountIn);
            }
        } else if (token == nativeToken)  {
            // caller must sent some native tokens
            if (
                msg.value < amountIn
            ) {
                revert CerbySwapV1_MsgValueProvidedMustBeLargerThanAmountIn();
            }

            // refunding extra native tokens
            // to make sure msg.value == amount
            if (msg.value > amountIn) {
                _safeTransferHelper(
                    nativeToken, 
                    msg.sender,
                    msg.value - amountIn,
                    false
                );
            }
        }
    }

    function _safeTransferHelper(address token, address to, uint amount, bool needToCheck)
        internal
    {
        // some transfer such as refund excess of msg.value
        // we don't check for bots
        if (needToCheck) {
            //checkTransactionForBots(token, msg.sender, to); // TODO: enable on production
        }

        if (to != address(this)) {
            if (token == nativeToken) {
                _safeTransferNative(to, amount);
            } else {
                _safeTransferToken(token, to, amount);
            }

        }
    }
    
    function _safeTransferToken(
        address token,
        address to,
        uint value
    ) internal {
        // 0xa9059cbb = bytes4(keccak256(bytes('transfer(address,uint)')));
        (bool success, bytes memory data) = 
            token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        if (
            ! (success && (data.length == 0 || abi.decode(data, (bool))))
        ) {
            revert CerbySwapV1_SafeTransferTokensFailed();
        }
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint value
    ) internal {
        // 0x23b872dd = bytes4(keccak256(bytes('transferFrom(address,address,uint)')));
        (bool success, bytes memory data) = 
            token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        if (
            ! (success && (data.length == 0 || abi.decode(data, (bool))))
        ) {
            revert CerbySwapV1_SafeTransferFromFailed();
        }
    }

    function _safeTransferNative(address to, uint value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        if (
            !success
        ) {
            revert CerbySwapV1_SafeTransferNativeFailed();
        }
    }
}