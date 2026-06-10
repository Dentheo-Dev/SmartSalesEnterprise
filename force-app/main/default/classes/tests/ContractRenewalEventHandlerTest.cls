@IsTest
private class ContractRenewalEventHandlerTest {

    @TestSetup
    static void setup() {
        insert new Account(Name = 'Renewal Event Corp');
    }

    @IsTest
    static void testRenovacaoGeraTask() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Renewal Event Corp'];

        Contract_Renewal__c cr = new Contract_Renewal__c(
            Account__c              = acc.Id,
            Original_Contract_End__c = Date.today().addDays(15),
            Status__c               = 'Em Negociação',
            Renewal_Value__c        = 200000
        );
        insert cr;

        List<Contract_Renewal_Alert__e> events = new List<Contract_Renewal_Alert__e>{
            new Contract_Renewal_Alert__e(
                Contract_Renewal_Id__c   = String.valueOf(cr.Id),
                Account_Id__c            = String.valueOf(acc.Id),
                Account_Name__c          = 'Renewal Event Corp',
                Days_Until_Expiration__c = 15,
                Renewal_Value__c         = 200000
            )
        };

        Test.startTest();
        ContractRenewalEventHandler.handleAfterInsert(events);
        Test.stopTest();

        List<Task> tasks = [SELECT Subject, Priority FROM Task WHERE WhatId = :acc.Id];
        System.assertEquals(1, tasks.size(), 'Deve criar uma Task de renovação');
        System.assert(tasks[0].Subject.contains('Renewal Event Corp'), 'Subject deve conter nome da account');
        System.assert(tasks[0].Subject.contains('15'), 'Subject deve conter dias restantes');
    }

    @IsTest
    static void testRenovacaoUrgente7DiasHighPriority() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Renewal Event Corp'];

        Contract_Renewal__c cr = new Contract_Renewal__c(
            Account__c              = acc.Id,
            Original_Contract_End__c = Date.today().addDays(5),
            Status__c               = 'Em Negociação',
            Renewal_Value__c        = 50000
        );
        insert cr;

        List<Contract_Renewal_Alert__e> events = new List<Contract_Renewal_Alert__e>{
            new Contract_Renewal_Alert__e(
                Contract_Renewal_Id__c   = String.valueOf(cr.Id),
                Account_Id__c            = String.valueOf(acc.Id),
                Account_Name__c          = 'Renewal Event Corp',
                Days_Until_Expiration__c = 5,
                Renewal_Value__c         = 50000
            )
        };

        Test.startTest();
        ContractRenewalEventHandler.handleAfterInsert(events);
        Test.stopTest();

        Task t = [SELECT Priority FROM Task WHERE WhatId = :acc.Id LIMIT 1];
        System.assertEquals('High', t.Priority, '≤7 dias deve gerar Task com prioridade High');
    }

    @IsTest
    static void testRenovacaoNaoPrazoNormalPriority() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Renewal Event Corp'];

        Contract_Renewal__c cr = new Contract_Renewal__c(
            Account__c              = acc.Id,
            Original_Contract_End__c = Date.today().addDays(20),
            Status__c               = 'Em Negociação',
            Renewal_Value__c        = 80000
        );
        insert cr;

        List<Contract_Renewal_Alert__e> events = new List<Contract_Renewal_Alert__e>{
            new Contract_Renewal_Alert__e(
                Contract_Renewal_Id__c   = String.valueOf(cr.Id),
                Account_Id__c            = String.valueOf(acc.Id),
                Account_Name__c          = 'Renewal Event Corp',
                Days_Until_Expiration__c = 20,
                Renewal_Value__c         = 80000
            )
        };

        Test.startTest();
        ContractRenewalEventHandler.handleAfterInsert(events);
        Test.stopTest();

        Task t = [SELECT Priority FROM Task WHERE WhatId = :acc.Id LIMIT 1];
        System.assertEquals('Normal', t.Priority, '>7 dias deve gerar Task com prioridade Normal');
    }

    @IsTest
    static void testDescricaoContemDetalhes() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Renewal Event Corp'];

        Contract_Renewal__c cr = new Contract_Renewal__c(
            Account__c              = acc.Id,
            Original_Contract_End__c = Date.today().addDays(10),
            Status__c               = 'Em Negociação',
            Renewal_Value__c        = 99000
        );
        insert cr;

        List<Contract_Renewal_Alert__e> events = new List<Contract_Renewal_Alert__e>{
            new Contract_Renewal_Alert__e(
                Contract_Renewal_Id__c   = String.valueOf(cr.Id),
                Account_Id__c            = String.valueOf(acc.Id),
                Account_Name__c          = 'Renewal Event Corp',
                Days_Until_Expiration__c = 10,
                Renewal_Value__c         = 99000
            )
        };

        Test.startTest();
        ContractRenewalEventHandler.handleAfterInsert(events);
        Test.stopTest();

        Task t = [SELECT Description FROM Task WHERE WhatId = :acc.Id LIMIT 1];
        System.assert(t.Description.contains('10'), 'Description deve conter dias restantes');
        System.assert(t.Description.contains('Renewal Event Corp'), 'Description deve conter nome da account');
    }

    @IsTest
    static void testListaVaziaSemErro() {
        Test.startTest();
        ContractRenewalEventHandler.handleAfterInsert(
            new List<Contract_Renewal_Alert__e>()
        );
        Test.stopTest();
        System.assert(true, 'Lista vazia não deve lançar exceção');
    }
}
