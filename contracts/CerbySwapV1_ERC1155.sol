// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.12;

import "../openzeppelin/token/ERC1155/ERC1155.sol";
import "./CerbyCronJobsExecution.sol";

abstract contract CerbySwapV1_ERC1155 is ERC1155, CerbyCronJobsExecution {

    string contractName = "CerbySwapV1"; // Q: everything by default is
    string contractSymbol = "CS1";
    string urlPrefix = "https://data.cerby.fi/CerbySwap/v1/";

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

    function uri(
        uint256 _id
    )
        external
        view
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                urlPrefix,
                uint2str(_id), ".json"
            )
        );
    }

    function setApprovalForAll(
        address _operator,
        bool _approved
    )
        external
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

    function uint2str(
        uint256 _i
    )
        private
        pure
        returns (string memory str)
    {
        if (_i == 0) return "0";

        uint256 j = _i;
        uint256 length;

        while (j != 0) {
            length++;
            j /= 10;
        }

        bytes memory bstr = new bytes(length);
        uint256 k = length;

        j = _i;

        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }

        str = string(bstr);
    }
}
