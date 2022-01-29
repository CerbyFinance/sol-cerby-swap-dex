// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.11;


import "./openzeppelin/token/ERC1155/extensions/ERC1155Supply.sol";
import "./CerbyCronJobsExecution.sol";


abstract contract CerbySwapV1_ERC1155 is ERC1155Supply, CerbyCronJobsExecution {

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
        public
        view
        returns(string memory)
    {
        return _name;
    }

    function symbol()
        public
        view
        returns(string memory)
    {
        return _symbol;
    }

    function decimals()
        public
        pure
        returns(uint)
    {
        return 18;
    }

    function totalSupply()
        public
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
        public
        view
        virtual
        override
        returns(string memory)
    {
        return string(abi.encodePacked(_urlPrefix, id, ".json"));
    }

    function setApprovalForAll(address operator, bool approved) 
        public 
        virtual 
        override
        executeCronJobs()
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint id,
        uint amount,
        bytes memory data
    ) 
        public 
        virtual 
        override
        executeCronJobs()
    {
        if (
            from != _msgSender() &&
            !isApprovedForAll(from, _msgSender())
        ) {
            revert CerbySwapLP1155V1_CallerIsNotOwnerNorApproved();
        }
        
        _safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) 
        public 
        virtual 
        override 
        executeCronJobs()
    {
        if (
            from != _msgSender() &&
            !isApprovedForAll(from, _msgSender())
        ) {
            revert CerbySwapLP1155V1_CallerIsNotOwnerNorApproved();
        }

        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}