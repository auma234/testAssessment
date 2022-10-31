/*
 * @Created By : Uma Susheela Akella
 * @Created Date : 31/10/2022
 * @Description : Create a trigger for SalesAgentTriggerHandler and check validation.
 */
trigger SalesAgentTriggerHandler on Sales_Agent__c (after delete) {
    
    //List of Parent  id's 
    Set<Id> SalesAgentIds = new Set<Id>();
    for(Sales_Agent__c SalesAgent :trigger.old){
        if(SalesAgent.Id != null){
            SalesAgentIds.add(SalesAgent.Id);
        }
    }
    
    If(!SalesAgentIds.isEmpty()){
        List<Commission__c> commissionList = [SELECT Id FROM Commission__c WHERE Sales_Agent__c IN : SalesAgentIds]; 
        // Update the value in the list of records
        if(!commissionList.isEmpty()){
            delete commissionList;
        }
    }
}