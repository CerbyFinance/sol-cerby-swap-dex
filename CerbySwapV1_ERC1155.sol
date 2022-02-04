// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.11;

import "./openzeppelin/token/ERC1155/ERC1155.sol";
import "./CerbyCronJobsExecution.sol";

abstract contract CerbySwapV1_ERC1155 is ERC1155, CerbyCronJobsExecution {

    string internal contractName = "CerbySwapV1"; // Q: everything by default is internal
    string internal contractSymbol = "CS1";
    string internal urlPrefix = "https://data.cerby.fi/CerbySwap/v1/";

    error CerbySwapLP1155V1_TransactionsAreTemporarilyDisabled(); // Q: unsued?
    error CerbySwapLP1155V1_CallerIsNotOwnerNorApproved(); //

    constructor() ERC1155(
        string(abi.encodePacked(urlPrefix, "{id}.json"))
    ) {}

    function name()
        external
        view
        returns (string memory)
    {
        return contractName;
    }

    function symbol()
        external
        view
        returns (string memory)
    {
        return contractSymbol;
    }

    function decimals()
        external
        pure
        returns (uint256)
    {
        return 18;
    }

    function totalSupply()
        external
        view
        returns (uint256)
    {
        uint256 i;
        uint256 totalSupplyAmount;

        // i starts from 1
        while (contractTotalSupply[++i] > 0) {
            totalSupplyAmount += contractTotalSupply[i];
        }

        return totalSupplyAmount;
    }

    function uri(uint256 _id)
        external
        view
        virtual // why?
        override
        returns (string memory)
    {
        return string(
            abi.encodePacked(urlPrefix, _id, ".json")
        );
    }

    function setApprovalForAll(
        address _operator,
        bool _approved
    )
        external
        virtual // why?
        override
        executeCronJobs
    {
        _setApprovalForAll(
            msg.sender,
            _operator,
            _approved
        );
    }

    function _notOwnerNotApproved(
        address _from
    )
        internal
        pure
        returns (bool)
    {
        return _from == msg.sender && isApprovedForAll(_from, msg.sender);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes calldata _data
    )
        external
        virtual // why?
        override
        executeCronJobs
    {
        // Q: duplicate
        if (_notOwnerNotApproved(_from) == true) {
            revert CerbySwapLP1155V1_CallerIsNotOwnerNorApproved();
        }

        _safeTransferFrom(
            _from,
            _to,
            _id,
            _amount,
            _data
        );
    }

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes calldata _data
    )
        external
        virtual // why?
        override
        executeCronJobs
    {
        // Q: duplicate (created function)
        if (_notOwnerNotApproved(_from) == true) {
            revert CerbySwapLP1155V1_CallerIsNotOwnerNorApproved();
        }

        _safeBatchTransferFrom(
            _from,
            _to,
            _ids,
            _amounts,
            _data
        );
    }
}
