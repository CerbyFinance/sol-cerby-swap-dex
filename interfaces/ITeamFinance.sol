// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface ITeamFinance {
    function lockTokens(address _tokenAddress, address _withdrawalAddress, uint256 _amount, uint256 _unlockTime) external returns (uint256 _id);
}