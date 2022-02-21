// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.12;

import "./interfaces/ICerbyToken.sol";
import "./interfaces/ICerbyBotDetection.sol";

abstract contract CerbyCronJobsExecution {

    uint256 constant CERBY_BOT_DETECTION_CONTRACT_ID = 3;

    ICerbyToken constant CERBY_TOKEN_INSTANCE = ICerbyToken(
        0xdef1fac7Bf08f173D286BbBDcBeeADe695129840
    );

    error CerbyCronJobsExecution_TransactionsAreTemporarilyDisabled();

    modifier detectBotTransactionThenRegisterTransactionAndExecuteCronJobsAfter(
        address _tokenIn,
        address _from,
        address _tokenOut,
        address _to
    ) {
        ICerbyBotDetection iCerbyBotDetection = ICerbyBotDetection(
            getUtilsContractAtPos(
                CERBY_BOT_DETECTION_CONTRACT_ID
            )
        );
        if (iCerbyBotDetection.detectBotTransaction(_tokenIn, _from)) {
            revert CerbyCronJobsExecution_TransactionsAreTemporarilyDisabled();
        }
        iCerbyBotDetection.registerTransaction(
            _tokenOut,
            _to
        );

        _;

        iCerbyBotDetection.executeCronJobs();
    }

    modifier checkForBotsAndExecuteCronJobsAfter(
        address _from
    ) {
        ICerbyBotDetection iCerbyBotDetection = ICerbyBotDetection(
            getUtilsContractAtPos(
                CERBY_BOT_DETECTION_CONTRACT_ID
            )
        );
        if (iCerbyBotDetection.isBotAddress(_from)) {
            revert CerbyCronJobsExecution_TransactionsAreTemporarilyDisabled();
        }

        _;

        iCerbyBotDetection.executeCronJobs();
    }

    function getUtilsContractAtPos(
        uint256 _pos
    )
        public
        view
        virtual
        returns (address)
    {
        return CERBY_TOKEN_INSTANCE.getUtilsContractAtPos(_pos);
    }
}
