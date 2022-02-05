// SPDX-License-Identifier: BSD-2-Clause

pragma solidity ^0.8.11;

interface ICerbyTokenMinterBurner {

    function balanceOf(
        address _account
    )
        external
        view
        returns (uint256);

    function totalSupply()
        external
        view
        returns (uint256);

    function mintHumanAddress(
        address _to,
        uint256 _desiredAmountToMint
    )
        external;

    function burnHumanAddress(
        address _from,
        uint256 _desiredAmountToBurn
    )
        external;

    function transferCustom(
        address _sender,
        address _recipient,
        uint256 _amount
    )
        external;

    function getUtilsContractAtPos(
        uint256 pos
    )
        external
        view
        returns (address);
}
