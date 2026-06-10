@IsTest
private class CommissionCalculatorServiceTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Commission Test Account');
        insert acc;

        List<Opportunity> opps = new List<Opportunity>();
        opps.add(new Opportunity(
            Name = 'Opp 5k', AccountId = acc.Id,
            Amount = 5000, StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        ));
        opps.add(new Opportunity(
            Name = 'Opp 20k', AccountId = acc.Id,
            Amount = 20000, StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        ));
        opps.add(new Opportunity(
            Name = 'Opp 100k', AccountId = acc.Id,
            Amount = 100000, StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        ));
        opps.add(new Opportunity(
            Name = 'Opp 300k', AccountId = acc.Id,
            Amount = 300000, StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        ));
        insert opps;
    }

    @IsTest
    static void testTier1Abaixo10k() {
        Opportunity opp = [SELECT Id, Amount, OwnerId FROM Opportunity WHERE Name = 'Opp 5k'];

        Test.startTest();
        CommissionCalculatorService.calculateCommission(new List<Opportunity>{ opp });
        Test.stopTest();

        Commission__c comm = [
            SELECT Commission_Rate__c, Commission_Amount__c, Status__c
            FROM Commission__c WHERE Opportunity__c = :opp.Id
        ];
        System.assertEquals(3, comm.Commission_Rate__c,   'Taxa esperada: 3%');
        System.assertEquals(150, comm.Commission_Amount__c, 'Comissão esperada: R$150');
        System.assertEquals('Calculada', comm.Status__c,  'Status deve ser Calculada');
    }

    @IsTest
    static void testTier2De10kA50k() {
        Opportunity opp = [SELECT Id, Amount, OwnerId FROM Opportunity WHERE Name = 'Opp 20k'];

        Test.startTest();
        CommissionCalculatorService.calculateCommission(new List<Opportunity>{ opp });
        Test.stopTest();

        Commission__c comm = [
            SELECT Commission_Rate__c, Commission_Amount__c
            FROM Commission__c WHERE Opportunity__c = :opp.Id
        ];
        System.assertEquals(5, comm.Commission_Rate__c,    'Taxa esperada: 5%');
        System.assertEquals(1000, comm.Commission_Amount__c, 'Comissão esperada: R$1.000');
    }

    @IsTest
    static void testTier3De50kA200k() {
        Opportunity opp = [SELECT Id, Amount, OwnerId FROM Opportunity WHERE Name = 'Opp 100k'];

        Test.startTest();
        CommissionCalculatorService.calculateCommission(new List<Opportunity>{ opp });
        Test.stopTest();

        Commission__c comm = [
            SELECT Commission_Rate__c, Commission_Amount__c
            FROM Commission__c WHERE Opportunity__c = :opp.Id
        ];
        System.assertEquals(7,    comm.Commission_Rate__c,   'Taxa esperada: 7%');
        System.assertEquals(7000, comm.Commission_Amount__c, 'Comissão esperada: R$7.000');
    }

    @IsTest
    static void testTier4Acima200k() {
        Opportunity opp = [SELECT Id, Amount, OwnerId FROM Opportunity WHERE Name = 'Opp 300k'];

        Test.startTest();
        CommissionCalculatorService.calculateCommission(new List<Opportunity>{ opp });
        Test.stopTest();

        Commission__c comm = [
            SELECT Commission_Rate__c, Commission_Amount__c
            FROM Commission__c WHERE Opportunity__c = :opp.Id
        ];
        System.assertEquals(10,    comm.Commission_Rate__c,   'Taxa esperada: 10%');
        System.assertEquals(30000, comm.Commission_Amount__c, 'Comissão esperada: R$30.000');
    }

    @IsTest
    static void testUpsertNaoCriaRegistroDuplicado() {
        Opportunity opp = [SELECT Id, Amount, OwnerId FROM Opportunity WHERE Name = 'Opp 20k'];

        Test.startTest();
        CommissionCalculatorService.calculateCommission(new List<Opportunity>{ opp });
        opp.Amount = 45000;
        CommissionCalculatorService.calculateCommission(new List<Opportunity>{ opp });
        Test.stopTest();

        Integer count = [SELECT COUNT() FROM Commission__c WHERE Opportunity__c = :opp.Id];
        System.assertEquals(1, count, 'Deve existir apenas uma comissão por oportunidade');
    }

    @IsTest
    static void testCommissionCalculatedFlagAtualizado() {
        Opportunity opp = [SELECT Id, Amount, OwnerId FROM Opportunity WHERE Name = 'Opp 5k'];

        Test.startTest();
        CommissionCalculatorService.calculateCommission(new List<Opportunity>{ opp });
        Test.stopTest();

        Opportunity updated = [SELECT Commission_Calculated__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(true, updated.Commission_Calculated__c, 'Flag Commission_Calculated__c deve ser true');
    }

    @IsTest
    static void testAmountNuloNaoCriaComissao() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Commission Test Account' LIMIT 1];
        Opportunity nullOpp = new Opportunity(
            Name = 'Opp Sem Valor', AccountId = acc.Id,
            StageName = 'Prospecting', CloseDate = Date.today().addDays(10)
        );
        insert nullOpp;

        nullOpp = [SELECT Id, Amount, OwnerId FROM Opportunity WHERE Id = :nullOpp.Id];

        Test.startTest();
        CommissionCalculatorService.calculateCommission(new List<Opportunity>{ nullOpp });
        Test.stopTest();

        Integer count = [SELECT COUNT() FROM Commission__c WHERE Opportunity__c = :nullOpp.Id];
        System.assertEquals(0, count, 'Sem Amount, nenhuma comissão deve ser criada');
    }

    @IsTest
    static void testPeriodoPreenchidoCorretamente() {
        Opportunity opp = [SELECT Id, Amount, OwnerId FROM Opportunity WHERE Name = 'Opp 5k'];

        Test.startTest();
        CommissionCalculatorService.calculateCommission(new List<Opportunity>{ opp });
        Test.stopTest();

        Commission__c comm = [SELECT Period__c FROM Commission__c WHERE Opportunity__c = :opp.Id];
        String expectedPeriod = String.valueOf(Date.today().year()) + '-'
                              + String.valueOf(Date.today().month()).leftPad(2, '0');
        System.assertEquals(expectedPeriod, comm.Period__c, 'Período deve estar no formato YYYY-MM');
    }
}
