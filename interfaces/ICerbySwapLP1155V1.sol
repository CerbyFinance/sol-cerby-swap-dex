// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.11;


interface ICerbySwapLP1155V1 {

    function balanceOf(address account, uint id) 
        external 
        view 
        returns (uint);

    function setApprovalForAll(address operator, bool approved) 
        external;

    function safeTransferFrom(
        address from,
        address to,
        uint id,
        uint amount,
        bytes memory data
    ) 
        external;
    
    function safeBatchTransferFrom(
        address from,
        address to,
        uint[] memory ids,
        uint[] memory amounts,
        bytes memory data
    ) 
        external;

    function adminSafeTransferFrom(
        address from,
        address to,
        uint id,
        uint amount
    ) 
        external;
    
    function adminSafeBatchTransferFrom(
        address from,
        address to,
        uint[] memory ids,
        uint[] memory amounts
    ) 
        external;

    function adminMint(
        address to,
        uint id,
        uint amount
    ) 
        external;

    function adminMintBatch(
        address to,
        uint[] memory ids,
        uint[] memory amounts
    ) 
        external;

    function adminBurn(
        address from,
        uint id,
        uint amount
    ) 
        external;

    function burn(
        uint id,
        uint amount
    ) 
        external;

    function adminBurnBatch(
        address from,
        uint[] memory ids,
        uint[] memory amounts
    ) 
        external;

    function totalSupply(uint id) external view returns (uint);

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint id) external view returns (bool);
}