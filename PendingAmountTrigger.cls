/*
* @Created By : Uma Susheela Akella
* @Created Date : 31/10/2022
* @Description : Create a trigger for update total Pending amount for all of their Opportunities.
*/
trigger PendingAmountTrigger on Commission__c (after insert, after update, after delete) {
    
    //List for Opportunity Ids 
    Set<Id> OppIds = new Set<Id>();
    List<Opportunity> opptyList = new List<Opportunity>();
    if(trigger.isUpdate || trigger.isInsert){
        for(Commission__c c: trigger.new){
            if(c.Sales_Agent__c != null && c.Opportunity__c != null ){
                OppIds.add(c.Opportunity__c);
            }
        }    
    }
    if(trigger.isDelete){
        for(Commission__c c : trigger.old){
            if(c.Sales_Agent__c != null && c.Opportunity__c != null ){
                OppIds.add(c.Opportunity__c);
            }
        }    
    }
    if(OppIds.size() > 0){
        opptyList = [SELECT Id, Amount FROM Opportunity WHERE Id IN : OppIds AND StageName =:'Pending'];
        List<Sales_Agent__c> SalesAgentList = new List<Sales_Agent__c>();
        for(Commission__c c : trigger.new){
            Sales_Agent__c SalesAgentObj = new Sales_Agent__c();
            SalesAgentObj.Id = c.Sales_Agent__c;
            Double totalOpptyAmount = 0;
            for(Opportunity oppty : opptyList){
                if(oppty.Id == c.Opportunity__c && oppty.Amount != null){
                    totalOpptyAmount += oppty.Amount;
                }
            }
            SalesAgentObj.Amount_Pending__c = totalOpptyAmount;
            SalesAgentList.add(SalesAgentObj);
        }
        // Update the SalesAgent Pending Amount
        update SalesAgentList;
    }
    
}