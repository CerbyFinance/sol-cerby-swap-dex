// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.14;

import "./interfaces/ICerbyERC20.sol";

contract CerbySwapV1_Vault {

    ICerbyERC20 token;
    ICerbyERC20 constant CERBY_TOKEN = ICerbyERC20(0xE7126C0Fb4B1f5F79E5Bbec3948139dCF348B49C);
    address constant factory = 0xfAf360f184788b00623828165405D7F52820D789;

    error CerbySwapV1_Vault_CallerIsNotFactory();
    error CerbySwapV1_Vault_SafeTransferFailed();

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
        onlyFactory
    {
        token = _token;
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
        pure
        returns (ICerbyERC20)
    {
        return CERBY_TOKEN;
    }

    function token1()
        external
        view
        returns (ICerbyERC20)
    {
        return token;
    }
}
