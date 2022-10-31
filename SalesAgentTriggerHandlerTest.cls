@IsTest
private class SalesAgentTriggerHandlerTest {

    @TestSetup
    static void testSetup() {
        String uniqueUsername = 'testuser' + Datetime.now().getTime() + '@test.com';
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        User user = new User(
            Alias = 'stdus',
            Email = 'testuser@test.com',
            EmailEncodingKey = 'UTF-8',
            FirstName = 'Test',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey='en_US',
            ProfileId = profile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = uniqueUsername
        );
        insert user;
    }

    @IsTest
    // commissions are deleted when their parent sales agent is deleted
    static void destoryCommissions() {
        User user = [SELECT Id, Name FROM User WHERE Email = 'testuser@test.com'];
        System.runAs(user) {

            createOpportunities(user, 1, 1000, 'New');

            Test.startTest();
            Sales_Agent__c salesAgent = [SELECT Id FROM Sales_Agent__c];
            delete salesAgent;
            Test.stopTest();

            // validate Commission__c record
            List<Commission__c> commissionList = [SELECT Id FROM Commission__c];
            System.assertEquals(commissionList.size(), 0);
        }
    }

    private static void createOpportunities(User user, Integer n, Decimal amount, String stage) {
        List<Opportunity> opportunityList = new List<Opportunity>();
        for (Integer i = 0; i < n; i++) {
            Opportunity opportunity = new Opportunity();
            opportunity.OwnerId = user.Id;
            opportunity.Amount = amount;
            opportunity.StageName = stage;
            opportunity.Name = String.valueOf(Datetime.now().getTime());
            opportunity.CloseDate = Date.today();
            opportunityList.add(opportunity);
        }
        insert opportunityList;
    }

}