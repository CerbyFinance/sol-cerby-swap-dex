// SPDX-License-Identifier: BSD-2-Clause

pragma solidity ^0.8.10;

interface ICerbyTokenMinterBurner {
    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function mintHumanAddress(address to, uint256 desiredAmountToMint) external;

    function burnHumanAddress(address from, uint256 desiredAmountToBurn)
        external;

    function transferCustom(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function getUtilsContractAtPos(uint256 pos) external view returns (address);
}
