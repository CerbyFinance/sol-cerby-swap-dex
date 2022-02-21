// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.12;

import "../openzeppelin/token/ERC1155/ERC1155.sol";
import "./CerbyCronJobsExecution.sol";

abstract contract CerbySwapV1_ERC1155 is ERC1155, CerbyCronJobsExecution {

    string contractName = "CerbySwapV1";
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

        // i starts from 1 (skipping 0th pool)
        while (erc1155TotalSupply[++i] > 0) {
            totalSupplyAmount += erc1155TotalSupply[i];
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
                _uint2str(_id), ".json"
            )
        );
    }

    function setApprovalForAll(
        address _operator,
        bool _approved
    )
        external
        checkForBotsAndExecuteCronJobsAfter(msg.sender)
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
        bytes calldata 
    )
        external
        checkForBotsAndExecuteCronJobsAfter(_from)
        addressIsApproved(_from)
    {
        _safeTransferFrom(
            _from,
            _to,
            _id,
            _amount
        );
    }

    function _uint2str(
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
