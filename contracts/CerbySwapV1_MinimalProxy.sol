// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// original code
// https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol

import "./CerbySwapV1_Declarations.sol";

contract CerbySwapV1_MinimalProxy is CerbySwapV1_Declarations {

    function cloneVault(
        ICerbyERC20 _token
    )
        internal
        returns (ICerbySwapV1_Vault)
    {       
        bytes32 salt = _getSaltByToken(_token);

        bytes20 vaultImplementationBytes = bytes20(
            address(VAULT_IMPLEMENTATION)
        );

        address resultVaultAddress;
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), vaultImplementationBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            resultVaultAddress := create2(
                0,
                clone,
                0x37,
                salt
            )
        }

        return ICerbySwapV1_Vault(resultVaultAddress);
    }

    function _getCachedVaultCloneAddressByToken(
        ICerbyERC20 _token
    )
        internal
        // Notice: not view because it has to update cache on first run
        returns(ICerbySwapV1_Vault)
    {
        ICerbySwapV1_Vault vault = cachedTokenValues[_token].vaultAddress;
        if (address(vault) == address(0)) {
            vault = _generateVaultAddressByToken(
                _token
            );
            cachedTokenValues[_token].vaultAddress = vault;
        }

        return vault;
    }

    function _generateVaultAddressByToken(
        ICerbyERC20 _token
    )
        internal
        view
        returns(ICerbySwapV1_Vault)
    {
        bytes32 salt = _getSaltByToken(_token);

        address factory = address(this);
        address vaultCloneAddress;  
        address vaultImplementationAddress = address(VAULT_IMPLEMENTATION);
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, vaultImplementationAddress))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000
            )
            mstore(add(ptr, 0x38), shl(0x60, factory))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            vaultCloneAddress := keccak256(add(ptr, 0x37), 0x55)
        }

        return ICerbySwapV1_Vault(vaultCloneAddress);
    }

    function _getSaltByToken(
        ICerbyERC20 _token
    )
        internal
        view
        returns(bytes32)
    {        
        return keccak256(
            abi.encodePacked(
                _token,
                address(this) // factory
            )
        );
    }
}
