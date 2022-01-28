// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.10;

struct TransactionInfo {
    bool isBuy;
    bool isSell;
}

interface ICerbyBotDetection {
        
    function checkTransactionInfo(address tokenAddr, address sender, address recipient, uint recipientBalance, uint transferAmount)
        external
        returns (TransactionInfo memory output);
    
    function isBotAddress(address addr)
        external
        view
        returns (bool);

    function executeCronJobs()
        external;

    function checkTransaction(address tokenAddr, address addr)
        external
        returns (bool);
        
    function registerTransaction(address tokenAddr, address addr)
        external;
}