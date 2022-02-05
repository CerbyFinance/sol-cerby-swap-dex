// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.10;

struct TransactionInfo {
    bool isBuy;
    bool isSell;
}

interface ICerbyBotDetection {

    function checkTransactionInfo(
        address _tokenAddr,
        address _sender,
        address _recipient,
        uint256 _recipientBalance,
        uint256 _transferAmount
    )
        external
        returns (TransactionInfo memory output);

    function isBotAddress(
        address _addr
    )
        external
        view
        returns (bool);

    function executeCronJobs()
        external;

    function detectBotTransaction(
        address _tokenAddr,
        address _addr
    )
        external
        returns (bool);

    function registerTransaction(
        address _tokenAddr,
        address _addr
    )
        external;
}
