@IsTest
private class CustomerHealthEventHandlerTest {

    @TestSetup
    static void setup() {
        insert new Account(Name = 'Health Alert Corp');
    }

    @IsTest
    static void testStatusCriticoGeraTask() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Health Alert Corp'];

        List<Customer_Health_Alert__e> events = new List<Customer_Health_Alert__e>{
            new Customer_Health_Alert__e(
                Account_Id__c      = String.valueOf(acc.Id),
                Account_Name__c    = 'Health Alert Corp',
                Health_Score__c    = 15,
                Health_Status__c   = 'Crítico',
                Previous_Status__c = 'Em Risco'
            )
        };

        Test.startTest();
        CustomerHealthEventHandler.handleAfterInsert(events);
        Test.stopTest();

        List<Task> tasks = [SELECT Subject, Priority FROM Task WHERE WhatId = :acc.Id];
        System.assertEquals(1, tasks.size(), 'Status Crítico deve criar Task');
        System.assertEquals('High', tasks[0].Priority, 'Crítico deve ter prioridade High');
        System.assert(tasks[0].Subject.contains('Crítico'), 'Subject deve conter o status');
    }

    @IsTest
    static void testStatusEmRiscoGeraTaskNormal() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Health Alert Corp'];

        List<Customer_Health_Alert__e> events = new List<Customer_Health_Alert__e>{
            new Customer_Health_Alert__e(
                Account_Id__c      = String.valueOf(acc.Id),
                Account_Name__c    = 'Health Alert Corp',
                Health_Score__c    = 45,
                Health_Status__c   = 'Em Risco',
                Previous_Status__c = 'Saudável'
            )
        };

        Test.startTest();
        CustomerHealthEventHandler.handleAfterInsert(events);
        Test.stopTest();

        List<Task> tasks = [SELECT Priority FROM Task WHERE WhatId = :acc.Id];
        System.assertEquals(1, tasks.size(), 'Status Em Risco deve criar Task');
        System.assertEquals('Normal', tasks[0].Priority, 'Em Risco deve ter prioridade Normal');
    }

    @IsTest
    static void testStatusSaudavelNaoGeraTask() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Health Alert Corp'];

        List<Customer_Health_Alert__e> events = new List<Customer_Health_Alert__e>{
            new Customer_Health_Alert__e(
                Account_Id__c      = String.valueOf(acc.Id),
                Account_Name__c    = 'Health Alert Corp',
                Health_Score__c    = 85,
                Health_Status__c   = 'Saudável',
                Previous_Status__c = 'Excelente'
            )
        };

        Test.startTest();
        CustomerHealthEventHandler.handleAfterInsert(events);
        Test.stopTest();

        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :acc.Id];
        System.assertEquals(0, tasks.size(), 'Status Saudável não deve criar Task');
    }

    @IsTest
    static void testTaskContemNomeAccount() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Health Alert Corp'];

        List<Customer_Health_Alert__e> events = new List<Customer_Health_Alert__e>{
            new Customer_Health_Alert__e(
                Account_Id__c      = String.valueOf(acc.Id),
                Account_Name__c    = 'Health Alert Corp',
                Health_Score__c    = 10,
                Health_Status__c   = 'Crítico',
                Previous_Status__c = 'Saudável'
            )
        };

        Test.startTest();
        CustomerHealthEventHandler.handleAfterInsert(events);
        Test.stopTest();

        Task t = [SELECT Subject, Description FROM Task WHERE WhatId = :acc.Id LIMIT 1];
        System.assert(t.Subject.contains('Health Alert Corp'), 'Subject deve conter nome da account');
        System.assert(t.Description.contains('10'), 'Description deve conter o score');
    }

    @IsTest
    static void testListaVaziaSemErro() {
        Test.startTest();
        CustomerHealthEventHandler.handleAfterInsert(
            new List<Customer_Health_Alert__e>()
        );
        Test.stopTest();
        System.assert(true, 'Lista vazia não deve lançar exceção');
    }
}
