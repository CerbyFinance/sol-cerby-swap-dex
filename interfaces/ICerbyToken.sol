// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

struct AccessSettings {
    bool isMinter;
    bool isBurner;
    bool isTransferer;
    bool isModerator;
    bool isTaxer;
    address addr;
}

interface ICerbyToken {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address _spender, uint256 _value)
        external
        returns (bool success);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function mintHumanAddress(address to, uint256 desiredAmountToMint) external;

    function burnHumanAddress(address from, uint256 desiredAmountToBurn)
        external;

    function mintByBridge(address to, uint256 realAmountToMint) external;

    function burnByBridge(address from, uint256 realAmountBurn) external;

    function getUtilsContractAtPos(uint256 pos) external view returns (address);

    function updateUtilsContracts(AccessSettings[] calldata accessSettings)
        external;

    function transferCustom(
        address sender,
        address recipient,
        uint256 amount
    ) external;
}
