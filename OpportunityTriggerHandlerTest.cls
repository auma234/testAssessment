@IsTest
private class OpportunityTriggerHandlerTest {

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
    // creates a single 'New' opportunity
    static void createSingleNewOpportunity() {
        User user = [SELECT Id, Name FROM User WHERE Email = 'testuser@test.com'];
        System.runAs(user) {

            Test.startTest();
            createOpportunities(user, 1, 1000, 'New');
            Test.stopTest();

            List<Opportunity> opportunityList = [SELECT Id, OwnerId, Amount, StageName, CloseDate FROM Opportunity];
            List<Sales_Agent__c> salesAgentList = [SELECT Id, OwnerId, Name, Amount_Pending__c FROM Sales_Agent__c];
            List<Commission__c> commissionList = [SELECT Id, Opportunity__c, Sales_Agent__c FROM Commission__c];

            // validate Opportunity record
            System.assertEquals(opportunityList.size(), 1);
            System.assertEquals(opportunityList[0].CloseDate, Date.today());
            System.assertEquals(opportunityList[0].StageName, 'New');
            System.assertEquals(opportunityList[0].OwnerId, user.Id);
            System.assertEquals(opportunityList[0].Amount, 1000);

            // validate Commission__c record
            System.assertEquals(commissionList.size(), 1);
            System.assertEquals(commissionList[0].Opportunity__c, opportunityList[0].Id);
            System.assertEquals(commissionList[0].Sales_Agent__c, salesAgentList[0].Id);

            // validate Sales_Agent__c record
            System.assertEquals(salesAgentList.size(), 1);
            System.assertEquals(salesAgentList[0].Amount_Pending__c, 100);
            System.assertEquals(salesAgentList[0].OwnerId, user.Id);
            System.assertEquals(salesAgentList[0].Name, user.Name);
        }
    }

    @IsTest
    // creates multiple 'New' opportunities for a single sales agent (assign sum commission)
    static void createMultipleNewOpportunities() {
        User user = [SELECT Id, Name FROM User WHERE Email = 'testuser@test.com'];
        System.runAs(user) {

            Test.startTest();
            createOpportunities(user, 3, 1000, 'New');
            Test.stopTest();

            List<Opportunity> opportunityList = [SELECT Id, OwnerId, Amount, StageName, CloseDate FROM Opportunity];
            List<Sales_Agent__c> salesAgentList = [SELECT Id, OwnerId, Name, Amount_Pending__c FROM Sales_Agent__c];
            List<Commission__c> commissionList = [SELECT Id, Opportunity__c, Sales_Agent__c FROM Commission__c];

            // validate Opportunity record
            System.assertEquals(opportunityList.size(), 3);
            System.assertEquals(opportunityList[0].CloseDate, Date.today());
            System.assertEquals(opportunityList[0].StageName, 'New');
            System.assertEquals(opportunityList[0].OwnerId, user.Id);
            System.assertEquals(opportunityList[0].Amount, 1000);

            // validate Commission__c record
            System.assertEquals(commissionList.size(), 3);
            for (Integer i = 0; i < commissionList.size(); i++) {
                System.assertEquals(commissionList[i].Opportunity__c, opportunityList[i].Id);
                System.assertEquals(commissionList[i].Sales_Agent__c, salesAgentList[0].Id);
            }

            // validate Sales_Agent__c record
            System.assertEquals(salesAgentList.size(), 1);
            System.assertEquals(salesAgentList[0].Amount_Pending__c, 300);
            System.assertEquals(salesAgentList[0].OwnerId, user.Id);
            System.assertEquals(salesAgentList[0].Name, user.Name);
        }
    }

    @IsTest
    // creates a single 'Prospecting' opportunity (do not execute trigger handler logic)
    static void createSingleProspectingOpportunity() {
        User user = [SELECT Id, Name FROM User WHERE Email = 'testuser@test.com'];
        System.runAs(user) {

            Test.startTest();
            createOpportunities(user, 1, 1000, 'Prospecting');
            Test.stopTest();

            List<Opportunity> opportunityList = [SELECT Id, OwnerId, Amount, StageName, CloseDate FROM Opportunity];
            List<Sales_Agent__c> salesAgentList = [SELECT Id, OwnerId, Name, Amount_Pending__c FROM Sales_Agent__c];
            List<Commission__c> commissionList = [SELECT Id, Opportunity__c, Sales_Agent__c FROM Commission__c];

            // validate Opportunity record
            System.assertEquals(opportunityList.size(), 1);
            System.assertEquals(opportunityList[0].CloseDate, Date.today());
            System.assertEquals(opportunityList[0].StageName, 'Prospecting');
            System.assertEquals(opportunityList[0].OwnerId, user.Id);
            System.assertEquals(opportunityList[0].Amount, 1000);

            // validate Commission__c record
            System.assertEquals(commissionList.size(), 0);

            // validate Sales_Agent__c record
            System.assertEquals(salesAgentList.size(), 0);
        }
    }

    @IsTest
    // commissions are deleted when their parent opportunity is deleted
    static void destoryCommissions() {
        User user = [SELECT Id, Name FROM User WHERE Email = 'testuser@test.com'];
        System.runAs(user) {

            createOpportunities(user, 1, 1000, 'New');

            Test.startTest();
            Opportunity opportunity = [SELECT Id FROM Opportunity];
            delete opportunity;
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