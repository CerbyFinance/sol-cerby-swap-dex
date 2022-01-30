// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.11;


import "./openzeppelin/token/ERC1155/ERC1155.sol";
import "./CerbyCronJobsExecution.sol";


abstract contract CerbySwapV1_ERC1155 is 
    ERC1155, 
    CerbyCronJobsExecution 
{

    string internal _name = "CerbySwapV1";
    string internal _symbol = "CS1";
    string internal _urlPrefix = "https://data.cerby.fi/CerbySwap/v1/";

    error CerbySwapLP1155V1_TransactionsAreTemporarilyDisabled();
    error CerbySwapLP1155V1_CallerIsNotOwnerNorApproved();

    constructor()
        ERC1155(string(abi.encodePacked(_urlPrefix, "{id}.json")))
    {
    }

    function name()
        external
        view
        returns(string memory)
    {
        return _name;
    }

    function symbol()
        external
        view
        returns(string memory)
    {
        return _symbol;
    }

    function decimals()
        external
        pure
        returns(uint)
    {
        return 18;
    }

    function totalSupply()
        external
        view
        returns(uint)
    {
        uint i;
        uint totalSupplyAmount;
        while(_totalSupply[++i] > 0) {
            totalSupplyAmount += _totalSupply[i];
        }
        return totalSupplyAmount;
    }

    function uri(uint id)
        external
        view
        virtual
        override
        returns(string memory)
    {
        return string(abi.encodePacked(_urlPrefix, id, ".json"));
    }

    function setApprovalForAll(address operator, bool approved) 
        external 
        virtual 
        override
        executeCronJobs()
    {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint id,
        uint amount,
        bytes calldata data
    ) 
        external 
        virtual 
        override
        executeCronJobs()
    {
        if (
            from != msg.sender &&
            !isApprovedForAll(from, msg.sender)
        ) {
            revert CerbySwapLP1155V1_CallerIsNotOwnerNorApproved();
        }
        
        _safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) 
        external 
        virtual 
        override 
        executeCronJobs()
    {
        if (
            from != msg.sender &&
            !isApprovedForAll(from, msg.sender)
        ) {
            revert CerbySwapLP1155V1_CallerIsNotOwnerNorApproved();
        }

        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}