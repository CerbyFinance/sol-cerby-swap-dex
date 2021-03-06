// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// original code
// https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol

import "./CerbySwapV1_Declarations.sol";

contract CerbySwapV1_MinimalProxy is CerbySwapV1_Declarations {

    function cloneVault(
        address _token
    )
        internal
        returns (address)
    {       
        bytes32 salt = _getSaltByToken(_token);

        bytes20 vaultImplementationBytes = bytes20(
            VAULT_IMPLEMENTATION
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

        return resultVaultAddress;
    }

    function _getCachedVaultCloneAddressByToken(
        address _token
    )
        internal
        // Notice: not view because it has to update cache on first run
        returns(address)
    {
        address vault = cachedTokenValues[_token].vaultAddress;
        if (vault == address(0)) {
            vault = _generateVaultAddressByToken(
                _token
            );
            cachedTokenValues[_token].vaultAddress = vault;
        }

        return vault;
    }

    function _generateVaultAddressByToken(
        address _token
    )
        internal
        view
        returns (address)
    {
        bytes32 salt = _getSaltByToken(_token);

        address factory = address(this);
        address vaultCloneAddress;        
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, VAULT_IMPLEMENTATION))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000
            )
            mstore(add(ptr, 0x38), shl(0x60, factory))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            vaultCloneAddress := keccak256(add(ptr, 0x37), 0x55)
        }

        return vaultCloneAddress;
    }

    function _getSaltByToken(
        address _token
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
