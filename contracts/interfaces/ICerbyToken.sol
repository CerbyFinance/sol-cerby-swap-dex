// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

struct AccessSettings {
    bool isMinter;
    bool isBurner;
    bool isTransferer;
    bool isModerator;
    bool isTaxer;
    address addr;
}

interface ICerbyToken {

    function allowance(
        address _owner,
        address _spender
    )
        external
        view
        returns (uint256);

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external returns (bool);

    function transfer(
        address _recipient,
        uint256 _amount
    )
        external
        returns (bool);

    function approve(
        address _spender,
        uint256 _value
    )
        external
        returns (bool success);

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

    function mintByBridge(
        address _to,
        uint256 _realAmountToMint
    )
        external;

    function burnByBridge(
        address _from,
        uint256 _realAmountBurn
    )
        external;

    function getUtilsContractAtPos(
        uint256 _pos
    )
        external
        view
        returns (address);

    function updateUtilsContracts(
        AccessSettings[] calldata accessSettings
    )
        external;

    function transferCustom(
        address _sender,
        address _recipient,
        uint256 _amount
    )
        external;
}
