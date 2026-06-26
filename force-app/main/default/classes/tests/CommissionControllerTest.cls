@IsTest
private class CommissionControllerTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Commission Controller Corp');
        insert acc;

        Opportunity opp = new Opportunity(
            Name      = 'Commission Controller Opp',
            AccountId = acc.Id,
            Amount    = 100000,
            StageName = 'Closed Won',
            CloseDate = Date.today()
        );
        insert opp;
        // O trigger afterInsert cria a Commission automaticamente via CommissionCalculatorService
    }

    @IsTest
    static void testGetCommissionSummary() {
        Test.startTest();
        Map<String, Object> summary = CommissionController.getCommissionSummary();
        Test.stopTest();

        System.assertNotEquals(null, summary, 'Summary não deve ser null');
        System.assert(summary.containsKey('totalGeral'), 'Deve conter totalGeral');
        System.assert(summary.containsKey('totalCalculada'), 'Deve conter totalCalculada');
        System.assert((Decimal) summary.get('totalCalculada') > 0, 'Deve ter comissão calculada');
    }

    @IsTest
    static void testGetCommissionsSemFiltro() {
        Test.startTest();
        List<Commission__c> result = CommissionController.getCommissions(null, null);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Deve retornar 1 comissão');
    }

    @IsTest
    static void testGetCommissionsPorStatus() {
        Test.startTest();
        List<Commission__c> result = CommissionController.getCommissions('Calculada', null);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Deve retornar 1 comissão com status Calculada');
    }

    @IsTest
    static void testGetCommissionsPorPeriodo() {
        String period = String.valueOf(Date.today().year()) + '-'
                      + String.valueOf(Date.today().month()).leftPad(2, '0');

        Test.startTest();
        List<Commission__c> result = CommissionController.getCommissions(null, period);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Deve retornar 1 comissão no período');
    }

    @IsTest
    static void testGetCommissionsStatusInexistente() {
        Test.startTest();
        List<Commission__c> result = CommissionController.getCommissions('StatusNaoExiste', null);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Status inexistente deve retornar lista vazia');
    }

    @IsTest
    static void testSummaryComTodosOsStatus() {
        Commission__c base = [SELECT Opportunity__c FROM Commission__c LIMIT 1];

        // Inserir comissões com outros status para cobrir todos os branches
        insert new List<Commission__c>{
            new Commission__c(
                Name = 'Paga Test', Opportunity__c = base.Opportunity__c,
                Sales_Rep__c = UserInfo.getUserId(), Commission_Amount__c = 3000,
                Commission_Rate__c = 3, Status__c = 'Paga', Period__c = '2025-01'
            ),
            new Commission__c(
                Name = 'Pendente Test', Opportunity__c = base.Opportunity__c,
                Sales_Rep__c = UserInfo.getUserId(), Commission_Amount__c = 5000,
                Commission_Rate__c = 5, Status__c = 'Pendente', Period__c = '2025-01'
            )
        };

        Test.startTest();
        Map<String, Object> summary = CommissionController.getCommissionSummary();
        Test.stopTest();

        System.assert((Decimal) summary.get('totalPago') > 0, 'Deve ter total pago');
        System.assert((Decimal) summary.get('totalPendente') > 0, 'Deve ter total pendente');
        System.assert((Decimal) summary.get('totalGeral') > 0, 'Total geral deve ser maior que zero');
    }
}
