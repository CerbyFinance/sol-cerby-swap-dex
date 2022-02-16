// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.11;

import "./interfaces/IBasicERC20.sol";
import "./interfaces/ICerbySwapV1_VaultImplementation.sol";
import "./CerbySwapV1_MinimalProxy.sol";
import "./CerbySwapV1_EventsAndErrors.sol";

abstract contract CerbySwapV1_SafeFunctions is
    CerbySwapV1_EventsAndErrors,
    CerbySwapV1_MinimalProxy
{
    function _getPoolBalances(
        address _token
    )
        internal
        view
        returns (PoolBalances memory)
    {
        address vault = getVaultCloneAddressByToken(
            _token
        );

        return PoolBalances(
            _getTokenBalance(_token, vault),
            _getTokenBalance(cerUsdToken, vault)
        );
    }

    function _getTokenBalance(
        address _token,
        address _vault
    )
        internal
        view
        returns (uint256)
    {
        return _token == nativeToken
            ? _vault.balance
            : IBasicERC20(_token).balanceOf(_vault);
    }

    function _safeTransferFromHelper(
        address _token,
        address _from,
        address _to,
        uint256 _amountTokens
    )
        internal
    {
        if (_from == _to) {
            revert("equal");
        }

        if (_amountTokens <= 1) { // Q3: || _from == _to this can be removed
            // revert("F");
            return; // Q3: should this revert somehow or remove whenever _safeTransferFromHelper is used?
            // since same would happen anyway later on could revert much earlier (see other remarks)
        }

        if (_token != nativeToken) {
            // _safeCoreTransferFrom does not require return value
            _safeCoreTransferFrom(
                _token,
                _from,
                _to,
                _amountTokens
            );
            return;
        }

        // native tokens sender --> vault
        if (_from == msg.sender) {

            // sender must sent some native tokens
            uint256 nativeBalance = address(this).balance;

            // this can be removed -> double check -> already handled in _safeCoreTransferNative -> you will get "x2"
            if (nativeBalance < _amountTokens) { // Q3: can it be equal?? redundant
                revert("asd"); // Q3: can it be equal ?? is it needed?? would revert anyway
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

            _safeCoreTransferNative(
                _to,
                _amountTokens
            );

            return;
        }

        // native tokens vault --> _to
        ICerbySwapV1_VaultImplementation(_from).withdrawEth(
            _to,
            _amountTokens
        );
    }

    function _safeCoreTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _value
    )
        internal
    {
        // refer to https://github.com/Uniswap/solidity-lib/blob/master/contracts/libraries/TransferHelper.sol
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(
                0x23b872dd,
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
        // refer to https://github.com/Uniswap/solidity-lib/blob/master/contracts/libraries/TransferHelper.sol
        (bool success, ) = _to.call{value: _value}(new bytes(0));

        // we allow only successfull calls
        if (!success) {
            revert("x2"); // Q5: double check in _safeTransferFromHelper (no need to check there)
            revert CerbySwapV1_SafeTransferNativeFailed();
        }
    }
}
