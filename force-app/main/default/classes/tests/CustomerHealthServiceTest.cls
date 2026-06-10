@IsTest
private class CustomerHealthServiceTest {

    @TestSetup
    static void setup() {
        List<Account> accounts = new List<Account>();
        accounts.add(new Account(Name = 'Healthy Corp'));
        accounts.add(new Account(Name = 'At Risk Inc'));
        accounts.add(new Account(Name = 'No Health Yet'));
        insert accounts;
    }

    @IsTest
    static void testClienteSaudavel() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Healthy Corp'];

        insert new Customer_Health__c(
            Account__c        = acc.Id,
            Name              = 'Health Score',
            NPS_Score__c      = 9,
            Payment_Delays__c = 0
        );
        // Compra recente para evitar penalidade de "sem compra"
        insert new Opportunity(
            Name = 'Recent Deal', AccountId = acc.Id,
            Amount = 50000, StageName = 'Closed Won',
            CloseDate = Date.today().addDays(-30)
        );

        Test.startTest();
        CustomerHealthService.calculateHealth(new List<Id>{ acc.Id });
        Test.stopTest();

        Customer_Health__c result = [
            SELECT Health_Score__c, Health_Status__c
            FROM Customer_Health__c WHERE Account__c = :acc.Id
        ];
        // Base 70 + 20 (NPS > 8) = 90
        System.assert(result.Health_Score__c > 70,  'Score deve ser acima de 70');
        System.assertEquals('Excelente', result.Health_Status__c, 'Status deve ser Excelente');
    }

    @IsTest
    static void testClienteEmRisco() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'At Risk Inc'];

        insert new Customer_Health__c(
            Account__c        = acc.Id,
            Name              = 'Health Score',
            NPS_Score__c      = 4,   // < 5 → -20
            Payment_Delays__c = 3    // > 2 → -20
        );
        // Sem Opportunity → sem compra recente → -25

        Test.startTest();
        CustomerHealthService.calculateHealth(new List<Id>{ acc.Id });
        Test.stopTest();

        Customer_Health__c result = [
            SELECT Health_Score__c
            FROM Customer_Health__c WHERE Account__c = :acc.Id
        ];
        // Base 70 - 20 (NPS) - 20 (delays) - 25 (sem compra) = 5
        System.assert(result.Health_Score__c <= 30, 'Score crítico esperado');
    }

    @IsTest
    static void testCriaRegistroSeNaoExiste() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'No Health Yet'];

        Integer countBefore = [SELECT COUNT() FROM Customer_Health__c WHERE Account__c = :acc.Id];
        System.assertEquals(0, countBefore, 'Nenhum registro antes do cálculo');

        Test.startTest();
        CustomerHealthService.calculateHealth(new List<Id>{ acc.Id });
        Test.stopTest();

        Integer countAfter = [SELECT COUNT() FROM Customer_Health__c WHERE Account__c = :acc.Id];
        System.assertEquals(1, countAfter, 'Deve criar um Customer_Health__c');
    }

    @IsTest
    static void testPenalidadeMuitosCasesAbertos() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'No Health Yet'];

        insert new Customer_Health__c(Account__c = acc.Id, Name = 'Health Score');

        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < 6; i++) {
            cases.add(new Case(AccountId = acc.Id, Subject = 'Test Case ' + i));
        }
        insert cases;

        Test.startTest();
        CustomerHealthService.calculateHealth(new List<Id>{ acc.Id });
        Test.stopTest();

        Customer_Health__c result = [
            SELECT Health_Score__c, Open_Cases__c
            FROM Customer_Health__c WHERE Account__c = :acc.Id
        ];
        // Base 70 - 30 (6 cases) - 25 (sem compra) = 15
        System.assertEquals(6, Integer.valueOf(result.Open_Cases__c), 'Deve registrar 6 cases abertos');
        System.assert(result.Health_Score__c <= 30, 'Score deve ser crítico');
        System.assertEquals('Crítico', [SELECT Health_Status__c FROM Customer_Health__c WHERE Account__c = :acc.Id].Health_Status__c, 'Status deve ser Crítico');
    }

    @IsTest
    static void testBonusNpsAlto() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Healthy Corp'];

        insert new Customer_Health__c(
            Account__c   = acc.Id,
            Name         = 'Health Score',
            NPS_Score__c = 10  // > 8 → +20
        );
        insert new Opportunity(
            Name = 'Recent Deal2', AccountId = acc.Id,
            Amount = 10000, StageName = 'Closed Won',
            CloseDate = Date.today().addDays(-10)
        );

        Test.startTest();
        CustomerHealthService.calculateHealth(new List<Id>{ acc.Id });
        Test.stopTest();

        Customer_Health__c result = [
            SELECT Health_Score__c FROM Customer_Health__c WHERE Account__c = :acc.Id
        ];
        // Base 70 + 20 (NPS 10) = 90
        System.assertEquals(90, result.Health_Score__c, 'Score 90 esperado com NPS=10 e compra recente');
    }

    @IsTest
    static void testLastCalculatedPreenchido() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'No Health Yet'];

        Test.startTest();
        CustomerHealthService.calculateHealth(new List<Id>{ acc.Id });
        Test.stopTest();

        Customer_Health__c result = [
            SELECT Last_Calculated__c FROM Customer_Health__c WHERE Account__c = :acc.Id
        ];
        System.assertNotEquals(null, result.Last_Calculated__c, 'Last_Calculated__c deve ser preenchido');
    }

    @IsTest
    static void testListaVazia() {
        Test.startTest();
        CustomerHealthService.calculateHealth(new List<Id>());
        Test.stopTest();
        System.assert(true, 'Lista vazia não deve causar erro');
    }

    @IsTest
    static void testBulkMultiplasAccounts() {
        List<Account> accounts = [SELECT Id FROM Account];

        for (Account acc : accounts) {
            insert new Customer_Health__c(Account__c = acc.Id, Name = 'Health Score');
        }

        List<Id> accIds = new List<Id>();
        for (Account acc : accounts) {
            accIds.add(acc.Id);
        }

        Test.startTest();
        CustomerHealthService.calculateHealth(accIds);
        Test.stopTest();

        Integer count = [SELECT COUNT() FROM Customer_Health__c];
        System.assertEquals(accounts.size(), count, 'Deve ter um health record por account');
    }
}
