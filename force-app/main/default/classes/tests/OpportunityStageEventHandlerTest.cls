@IsTest
private class OpportunityStageEventHandlerTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Stage Test Corp');
        insert acc;

        insert new Opportunity(
            Name      = 'Stage Test Opp',
            AccountId = acc.Id,
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30),
            Amount    = 75000
        );
    }

    @IsTest
    static void testProposalStageGeraTask() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Stage Test Opp'];

        List<Opportunity_Stage_Changed__e> events = new List<Opportunity_Stage_Changed__e>{
            new Opportunity_Stage_Changed__e(
                Opportunity_Id__c = String.valueOf(opp.Id),
                Previous_Stage__c = 'Qualification',
                New_Stage__c      = 'Proposal/Price Quote',
                Amount__c         = 75000
            )
        };

        Test.startTest();
        OpportunityStageEventHandler.handleAfterInsert(events);
        Test.stopTest();

        List<Task> tasks = [SELECT Subject, Priority FROM Task WHERE WhatId = :opp.Id];
        System.assertEquals(1, tasks.size(), 'Deve criar Task para Proposal/Price Quote');
        System.assertEquals('Normal', tasks[0].Priority, 'Priority deve ser Normal para Proposal');
        System.assert(tasks[0].Subject.contains('Proposal'), 'Subject deve conter o stage');
    }

    @IsTest
    static void testClosedLostGeraTaskHighPriority() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Stage Test Opp'];

        List<Opportunity_Stage_Changed__e> events = new List<Opportunity_Stage_Changed__e>{
            new Opportunity_Stage_Changed__e(
                Opportunity_Id__c = String.valueOf(opp.Id),
                Previous_Stage__c = 'Negotiation/Review',
                New_Stage__c      = 'Closed Lost',
                Amount__c         = 75000
            )
        };

        Test.startTest();
        OpportunityStageEventHandler.handleAfterInsert(events);
        Test.stopTest();

        List<Task> tasks = [SELECT Priority FROM Task WHERE WhatId = :opp.Id];
        System.assertEquals(1, tasks.size(), 'Deve criar Task para Closed Lost');
        System.assertEquals('High', tasks[0].Priority, 'Closed Lost deve ter prioridade High');
    }

    @IsTest
    static void testStageNaoRelevantNaoGeraTask() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Stage Test Opp'];

        List<Opportunity_Stage_Changed__e> events = new List<Opportunity_Stage_Changed__e>{
            new Opportunity_Stage_Changed__e(
                Opportunity_Id__c = String.valueOf(opp.Id),
                Previous_Stage__c = 'Qualification',
                New_Stage__c      = 'Needs Analysis',
                Amount__c         = 75000
            )
        };

        Test.startTest();
        OpportunityStageEventHandler.handleAfterInsert(events);
        Test.stopTest();

        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :opp.Id];
        System.assertEquals(0, tasks.size(), 'Needs Analysis não deve criar Task');
    }

    @IsTest
    static void testNegotiationStageGeraTask() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Stage Test Opp'];

        List<Opportunity_Stage_Changed__e> events = new List<Opportunity_Stage_Changed__e>{
            new Opportunity_Stage_Changed__e(
                Opportunity_Id__c = String.valueOf(opp.Id),
                Previous_Stage__c = 'Proposal/Price Quote',
                New_Stage__c      = 'Negotiation/Review',
                Amount__c         = 75000
            )
        };

        Test.startTest();
        OpportunityStageEventHandler.handleAfterInsert(events);
        Test.stopTest();

        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :opp.Id];
        System.assertEquals(1, tasks.size(), 'Negotiation/Review deve criar Task');
    }

    @IsTest
    static void testListaVaziaSemErro() {
        Test.startTest();
        OpportunityStageEventHandler.handleAfterInsert(
            new List<Opportunity_Stage_Changed__e>()
        );
        Test.stopTest();
        System.assert(true, 'Lista vazia não deve lançar exceção');
    }
}
