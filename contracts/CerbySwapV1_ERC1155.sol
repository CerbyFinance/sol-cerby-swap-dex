// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.11;

import "../openzeppelin/token/ERC1155/ERC1155.sol";
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
        addressIsApproved(_from)
        executeCronJobs
    {
        _safeTransferFrom(
            _from,
            _to,
            _id,
            _amount,
            _data
        );
    }
}
