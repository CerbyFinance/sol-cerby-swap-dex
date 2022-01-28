// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

struct TaxAmountsInput {
    address sender;
    address recipient;
    uint transferAmount;
    uint senderRealBalance;
    uint recipientRealBalance;
}
struct TaxAmountsOutput {
    uint senderRealBalance;
    uint recipientRealBalance;
    uint burnAndRewardAmount;
    uint recipientGetsAmount;
}

interface INoBotsTech {
    
    function botTaxPercent()
        external
        returns (uint);
    
    function prepareTaxAmounts(
        TaxAmountsInput calldata taxAmountsInput
    ) 
        external
        returns(TaxAmountsOutput memory taxAmountsOutput);
    
    function updateSupply(uint _realTotalSupply, uint _rewardsBalance)
        external;
        
    function prepareHumanAddressMintOrBurnRewardsAmounts(bool isMint, address account, uint desiredAmountToMintOrBurn)
        external
        returns (uint realAmountToMintOrBurn);
        
    function getBalance(address account, uint accountBalance)
        external
        view
        returns(uint);
        
    function getRealBalance(address account, uint accountBalance)
        external
        view
        returns(uint);
        
    function getRealBalanceTeamVestingContract(uint accountBalance)
        external
        view
        returns(uint);
        
    function getTotalSupply()
        external
        view
        returns (uint);
        
    function grantRole(bytes32 role, address account) 
        external;
        
    function chargeCustomTax(uint taxAmount, uint accountBalance)
        external
        returns (uint);
    
    function chargeCustomTaxTeamVestingContract(uint taxAmount, uint accountBalance)
        external
        returns (uint);
        
    function publicForcedUpdateCacheMultiplier()
        external;
    
}