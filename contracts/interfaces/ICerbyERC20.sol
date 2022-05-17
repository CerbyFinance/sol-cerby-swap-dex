// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface ICerbyERC20 {

    function balanceOf(
        address _account
    )
        external
        view
        returns (uint256);

    function approve(
        address _spender,
        uint256 _value
    )
        external
        returns (bool success);
        
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
