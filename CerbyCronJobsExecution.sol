// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.11;

import "./interfaces/ICerbyToken.sol";
import "./interfaces/ICerbyBotDetection.sol";

abstract contract CerbyCronJobsExecution {

    uint internal constant CERBY_BOT_DETECTION_CONTRACT_ID = 3;
    address internal constant CERBY_TOKEN_CONTRACT_ADDRESS = 0xdef1fac7Bf08f173D286BbBDcBeeADe695129840;
    
    error CerbyCronJobsExecution_TransactionsAreTemporarilyDisabled();

    modifier checkForBotsAndExecuteCronJobs(address addr)
    {
        ICerbyBotDetection iCerbyBotDetection = ICerbyBotDetection(
            getUtilsContractAtPos(CERBY_BOT_DETECTION_CONTRACT_ID)
        );
        if (
            iCerbyBotDetection.isBotAddress(addr)
        ) {
            revert CerbyCronJobsExecution_TransactionsAreTemporarilyDisabled();
        }
        iCerbyBotDetection.executeCronJobs();
        _;
    }

    modifier executeCronJobs(address addr)
    {
        ICerbyBotDetection iCerbyBotDetection = ICerbyBotDetection(
            getUtilsContractAtPos(CERBY_BOT_DETECTION_CONTRACT_ID)
        );
        iCerbyBotDetection.executeCronJobs();
        _;
    }

    function getUtilsContractAtPos(uint pos)
        public
        view
        virtual
        returns (address)
    {
        return ICerbyToken(CERBY_TOKEN_CONTRACT_ADDRESS).getUtilsContractAtPos(pos);
    }
    
    modifier checkForBots(address addr)
    {
        ICerbyBotDetection iCerbyBotDetection = ICerbyBotDetection(
            ICerbyToken(CERBY_TOKEN_CONTRACT_ADDRESS).getUtilsContractAtPos(CERBY_BOT_DETECTION_CONTRACT_ID)
        );
        if (
            iCerbyBotDetection.isBotAddress(addr)
        ) {
            revert CerbyCronJobsExecution_TransactionsAreTemporarilyDisabled();
        }
        _;
    }
    
    modifier checkTransactionAndExecuteCron(address tokenAddr, address addr)
    {
        ICerbyBotDetection iCerbyBotDetection = ICerbyBotDetection(
            ICerbyToken(CERBY_TOKEN_CONTRACT_ADDRESS).getUtilsContractAtPos(CERBY_BOT_DETECTION_CONTRACT_ID)
        );
        if (
            iCerbyBotDetection.checkTransaction(tokenAddr, addr)
        ) {
            revert CerbyCronJobsExecution_TransactionsAreTemporarilyDisabled();
        }
        iCerbyBotDetection.executeCronJobs();
        _;
    }
}
