// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.11;

import "./interfaces/ICerbyToken.sol";
import "./interfaces/ICerbyBotDetection.sol";

abstract contract CerbyCronJobsExecution {

    uint256 constant CERBY_BOT_DETECTION_CONTRACT_ID = 3;
    ICerbyToken constant CERBY_TOKEN_INSTANCE = ICerbyToken(
        0xdef1fac7Bf08f173D286BbBDcBeeADe695129840
    );

    error CerbyCronJobsExecution_TransactionsAreTemporarilyDisabled();

    modifier checkForBotsAndExecuteCronJobs(address _addr) {
        ICerbyBotDetection iCerbyBotDetection = ICerbyBotDetection(
            getUtilsContractAtPos(CERBY_BOT_DETECTION_CONTRACT_ID)
        );
        if (iCerbyBotDetection.isBotAddress(_addr)) {
            revert CerbyCronJobsExecution_TransactionsAreTemporarilyDisabled();
        }
        iCerbyBotDetection.executeCronJobs();
        _;
    }

    modifier executeCronJobs() {
        ICerbyBotDetection iCerbyBotDetection = ICerbyBotDetection(
            getUtilsContractAtPos(CERBY_BOT_DETECTION_CONTRACT_ID)
        );
        iCerbyBotDetection.executeCronJobs();
        _;
    }

    function getUtilsContractAtPos(uint256 _pos)
        public
        view
        virtual
        returns (address)
    {
        return CERBY_TOKEN_INSTANCE.getUtilsContractAtPos(_pos);
    }

    modifier checkForBots(address _addr) {
        ICerbyBotDetection iCerbyBotDetection = ICerbyBotDetection(
            CERBY_TOKEN_INSTANCE.getUtilsContractAtPos(
                CERBY_BOT_DETECTION_CONTRACT_ID
            )
        );

        if (iCerbyBotDetection.isBotAddress(_addr)) {
            revert CerbyCronJobsExecution_TransactionsAreTemporarilyDisabled();
        }

        _;
    }

    modifier checkTransactionAndExecuteCron(
        address _tokenAddr,
        address _addr
    ) {
        ICerbyBotDetection iCerbyBotDetection = ICerbyBotDetection(
            CERBY_TOKEN_INSTANCE.getUtilsContractAtPos(
                CERBY_BOT_DETECTION_CONTRACT_ID
            )
        );

        if (iCerbyBotDetection.detectBotTransaction(_tokenAddr, _addr)) {
            revert CerbyCronJobsExecution_TransactionsAreTemporarilyDisabled();
        }

        iCerbyBotDetection.executeCronJobs();
        _;
    }

    function checkTransactionForBots(
        address _token,
        address _from,
        address _to
    )
        internal
    {
        ICerbyBotDetection iCerbyBotDetection = ICerbyBotDetection(
            CERBY_TOKEN_INSTANCE.getUtilsContractAtPos(
                CERBY_BOT_DETECTION_CONTRACT_ID
            )
        );

        if (iCerbyBotDetection.detectBotTransaction(_token, _from)) {
            revert CerbyCronJobsExecution_TransactionsAreTemporarilyDisabled();
        }

        if (_to == address(this)) return;

        iCerbyBotDetection.registerTransaction(
            _token,
            _to
        );
    }
}
