// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.11;


import "./openzeppelin/access/AccessControlEnumerable.sol";
import "./openzeppelin/token/ERC1155/extensions/ERC1155Supply.sol";
import "./CerbyCronJobsExecution.sol";


abstract contract CerbySwapLP1155V1 is ERC1155Supply, CerbyCronJobsExecution, AccessControlEnumerable {

    string _name = "Cerby Swap V1";
    string _symbol = "CERBY_SWAP_V1";
    string _urlPrefix = "https://data.cerby.fi/CerbySwap/v1/";

    error CerbySwapLP1155V1_TransactionsAreTemporarilyDisabled();
    error CerbySwapLP1155V1_CallerIsNotOwnerNorApproved();

    constructor()
        ERC1155(string(abi.encodePacked(_urlPrefix, "{id}.json")))
    {
    }

    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        virtual 
        override(ERC165, AccessControlEnumerable) 
        returns (bool) 
    {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
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

    function adminSetURI(string memory newUrlPrefix)
        public
        onlyRole(ROLE_ADMIN)
    {
        _setURI(string(abi.encodePacked(newUrlPrefix, "{id}.json")));

        _urlPrefix = newUrlPrefix;
    }

    function adminUpdateNameAndSymbol(string memory newName, string memory newSymbol)
        public
        onlyRole(ROLE_ADMIN)
    {
        _name = newName;
        _symbol = newSymbol;
    }

    function setApprovalForAll(address operator, bool approved) 
        public 
        virtual 
        override
        checkTransactionAndExecuteCron(address(this), msg.sender)
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
    {
        if (
            from != _msgSender() &&
            !isApprovedForAll(from, _msgSender())
        ) {
            revert CerbySwapLP1155V1_CallerIsNotOwnerNorApproved();
        }

        checkTransactionForBots(address(this), from, to);

        
        _safeTransferFrom(from, to, id, amount, data);
    }

    function burn(
        address account,
        uint id,
        uint value
    ) 
        public 
        virtual
    {
        if (
            account != _msgSender() &&
            !isApprovedForAll(account, _msgSender())
        ) {
            revert CerbySwapLP1155V1_CallerIsNotOwnerNorApproved();
        }

        _burn(account, id, value);
    }
}