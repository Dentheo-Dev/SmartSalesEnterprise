@IsTest
private class LeadScoredEventHandlerTest {

    @TestSetup
    static void setup() {
        insert new Lead(
            FirstName = 'Alto', LastName = 'Score',
            Company   = 'HighCo',
            Email     = 'alto@highco.com',
            Phone     = '(11) 99999-0001'
        );
        insert new Lead(
            FirstName = 'Baixo', LastName = 'Score',
            Company   = 'LowCo',
            Email     = 'baixo@gmail.com'
        );
    }

    @IsTest
    static void testScoreAltoGeraTask() {
        Lead lead = [SELECT Id FROM Lead WHERE LastName = 'Score' AND FirstName = 'Alto'];

        List<Lead_Scored__e> events = new List<Lead_Scored__e>{
            new Lead_Scored__e(
                Lead_Id__c      = String.valueOf(lead.Id),
                Score__c        = 80,
                Previous_Score__c = 0,
                Score_Reason__c = '+20 email corporativo | +60 outros critérios'
            )
        };

        Test.startTest();
        LeadScoredEventHandler.handleAfterInsert(events);
        Test.stopTest();

        List<Task> tasks = [SELECT Subject, Priority FROM Task WHERE WhoId = :lead.Id];
        System.assertEquals(1, tasks.size(), 'Deve criar uma Task para lead qualificado');
        System.assertEquals('High', tasks[0].Priority, 'Task deve ter prioridade High');
        System.assert(tasks[0].Subject.contains('80'), 'Subject deve conter o score');
    }

    @IsTest
    static void testScoreBaixoNaoGeraTask() {
        Lead lead = [SELECT Id FROM Lead WHERE LastName = 'Score' AND FirstName = 'Baixo'];

        List<Lead_Scored__e> events = new List<Lead_Scored__e>{
            new Lead_Scored__e(
                Lead_Id__c        = String.valueOf(lead.Id),
                Score__c          = 40,
                Previous_Score__c = 0,
                Score_Reason__c   = ''
            )
        };

        Test.startTest();
        LeadScoredEventHandler.handleAfterInsert(events);
        Test.stopTest();

        List<Task> tasks = [SELECT Id FROM Task WHERE WhoId = :lead.Id];
        System.assertEquals(0, tasks.size(), 'Score < 70 não deve criar Task');
    }

    @IsTest
    static void testScoreExatamente70GeraTask() {
        Lead lead = [SELECT Id FROM Lead WHERE LastName = 'Score' AND FirstName = 'Alto'];

        List<Lead_Scored__e> events = new List<Lead_Scored__e>{
            new Lead_Scored__e(
                Lead_Id__c        = String.valueOf(lead.Id),
                Score__c          = 70,
                Previous_Score__c = 0,
                Score_Reason__c   = '+70 qualificado'
            )
        };

        Test.startTest();
        LeadScoredEventHandler.handleAfterInsert(events);
        Test.stopTest();

        List<Task> tasks = [SELECT Id FROM Task WHERE WhoId = :lead.Id];
        System.assertEquals(1, tasks.size(), 'Score = 70 deve criar Task (no limiar)');
    }

    @IsTest
    static void testListaVaziaSemErro() {
        Test.startTest();
        LeadScoredEventHandler.handleAfterInsert(new List<Lead_Scored__e>());
        Test.stopTest();
        System.assert(true, 'Lista vazia não deve lançar exceção');
    }

    @IsTest
    static void testBulkMultiplosLeads() {
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 10; i++) {
            leads.add(new Lead(
                FirstName = 'Bulk', LastName = 'Lead' + i,
                Company   = 'BulkCo', Email = 'bulk' + i + '@corp.com'
            ));
        }
        insert leads;

        List<Lead_Scored__e> events = new List<Lead_Scored__e>();
        for (Lead l : leads) {
            events.add(new Lead_Scored__e(
                Lead_Id__c        = String.valueOf(l.Id),
                Score__c          = 75,
                Previous_Score__c = 0,
                Score_Reason__c   = '+75 bulk'
            ));
        }

        Test.startTest();
        LeadScoredEventHandler.handleAfterInsert(events);
        Test.stopTest();

        Integer taskCount = [SELECT COUNT() FROM Task WHERE Subject LIKE 'Lead Qualificado%'];
        System.assertEquals(10, taskCount, 'Deve criar uma Task por lead qualificado');
    }
}
