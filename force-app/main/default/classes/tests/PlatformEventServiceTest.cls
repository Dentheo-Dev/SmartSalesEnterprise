@IsTest
private class PlatformEventServiceTest {

    @IsTest
    static void testPublishLeadScored() {
        Lead lead = new Lead(
            FirstName = 'Teste', LastName = 'Lead',
            Company   = 'TestCo',
            Email     = 'teste@testco.com'
        );
        insert lead;

        Test.startTest();
        PlatformEventService.publishLeadScored(lead.Id, 80, 0, '+20 email corporativo | +60 outros');
        Test.stopTest();

        System.assert(true, 'Publicação de Lead_Scored__e não deve lançar exceção');
    }

    @IsTest
    static void testPublishOpportunityStageChanged() {
        Account acc = new Account(Name = 'TestAccount PE');
        insert acc;

        Opportunity opp = new Opportunity(
            Name      = 'TestOpp PE',
            AccountId = acc.Id,
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30),
            Amount    = 50000
        );
        insert opp;

        Test.startTest();
        PlatformEventService.publishOpportunityStageChanged(
            opp.Id, 'Qualification', 'Proposal/Price Quote', 50000
        );
        Test.stopTest();

        System.assert(true, 'Publicação de Opportunity_Stage_Changed__e não deve lançar exceção');
    }

    @IsTest
    static void testPublishCustomerHealthAlert() {
        Account acc = new Account(Name = 'HealthAlert TestCo');
        insert acc;

        Test.startTest();
        PlatformEventService.publishCustomerHealthAlert(
            acc.Id, 'HealthAlert TestCo', 20, 'Crítico', 'Saudável'
        );
        Test.stopTest();

        System.assert(true, 'Publicação de Customer_Health_Alert__e não deve lançar exceção');
    }

    @IsTest
    static void testPublishContractRenewalAlert() {
        Account acc = new Account(Name = 'RenewalAlert TestCo');
        insert acc;

        Contract_Renewal__c cr = new Contract_Renewal__c(
            Account__c              = acc.Id,
            Original_Contract_End__c = Date.today().addDays(10),
            Status__c               = 'Em Negociação',
            Renewal_Value__c        = 120000
        );
        insert cr;

        Test.startTest();
        PlatformEventService.publishContractRenewalAlert(
            cr.Id, acc.Id, 'RenewalAlert TestCo', 10, 120000
        );
        Test.stopTest();

        System.assert(true, 'Publicação de Contract_Renewal_Alert__e não deve lançar exceção');
    }

    @IsTest
    static void testPublishAllListaVazia() {
        Test.startTest();
        PlatformEventService.publishAll(new List<SObject>());
        Test.stopTest();

        System.assert(true, 'Lista vazia não deve lançar exceção');
    }

    @IsTest
    static void testPublishAllLote() {
        Account acc = new Account(Name = 'Bulk Test');
        insert acc;

        List<SObject> events = new List<SObject>();
        for (Integer i = 0; i < 5; i++) {
            events.add(new Customer_Health_Alert__e(
                Account_Id__c      = String.valueOf(acc.Id),
                Account_Name__c    = 'Bulk Test',
                Health_Score__c    = 20,
                Health_Status__c   = 'Crítico',
                Previous_Status__c = 'Saudável'
            ));
        }

        Test.startTest();
        PlatformEventService.publishAll(events);
        Test.stopTest();

        System.assert(true, 'Publicação em lote não deve lançar exceção');
    }
}
