@IsTest
private class ContractRenewalControllerTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Renewal Controller Corp');
        insert acc;

        insert new List<Contract_Renewal__c>{
            new Contract_Renewal__c(
                Name                     = 'Renewal 15',
                Account__c               = acc.Id,
                Original_Contract_End__c = Date.today().addDays(15),
                Renewal_Value__c         = 120000,
                Status__c                = 'Pendente'
            ),
            new Contract_Renewal__c(
                Name                     = 'Renewal 60',
                Account__c               = acc.Id,
                Original_Contract_End__c = Date.today().addDays(60),
                Renewal_Value__c         = 80000,
                Status__c                = 'Em Negociação'
            ),
            new Contract_Renewal__c(
                Name                     = 'Renewal Done',
                Account__c               = acc.Id,
                Original_Contract_End__c = Date.today().addDays(10),
                Renewal_Value__c         = 50000,
                Status__c                = 'Renovado'
            )
        };
    }

    @IsTest
    static void testGetExpiring90Dias() {
        Test.startTest();
        List<Contract_Renewal__c> result = ContractRenewalController.getExpiringContracts(90);
        Test.stopTest();

        System.assertEquals(2, result.size(), 'Deve retornar 2 contratos não renovados em 90 dias');
    }

    @IsTest
    static void testGetExpiring30Dias() {
        Test.startTest();
        List<Contract_Renewal__c> result = ContractRenewalController.getExpiringContracts(30);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Deve retornar apenas o contrato de 15 dias');
        System.assertEquals('Renewal 15', result[0].Name, 'Deve ser o Renewal 15');
    }

    @IsTest
    static void testGetExpiringNullUsaDefault() {
        Test.startTest();
        List<Contract_Renewal__c> result = ContractRenewalController.getExpiringContracts(null);
        Test.stopTest();

        System.assertEquals(2, result.size(), 'null deve usar default 90 dias');
    }

    @IsTest
    static void testGetExpiringZeroUsaDefault() {
        Test.startTest();
        List<Contract_Renewal__c> result = ContractRenewalController.getExpiringContracts(0);
        Test.stopTest();

        System.assertEquals(2, result.size(), '0 deve usar default 90 dias');
    }

    @IsTest
    static void testOrdenacaoPorData() {
        Test.startTest();
        List<Contract_Renewal__c> result = ContractRenewalController.getExpiringContracts(90);
        Test.stopTest();

        System.assertEquals(2, result.size(), 'Deve retornar 2 registros');
        System.assert(
            result[0].Original_Contract_End__c <= result[1].Original_Contract_End__c,
            'Deve estar ordenado por data ascendente'
        );
    }

    @IsTest
    static void testRenovadoNaoAparece() {
        List<Contract_Renewal__c> renovados = [
            SELECT Id FROM Contract_Renewal__c
            WHERE Status__c = 'Renovado'
        ];
        System.assertEquals(1, renovados.size(), 'Setup criou 1 contrato Renovado');

        Test.startTest();
        List<Contract_Renewal__c> result = ContractRenewalController.getExpiringContracts(90);
        Test.stopTest();

        for (Contract_Renewal__c c : result) {
            System.assertNotEquals('Renovado', c.Status__c, 'Renovados não devem aparecer');
        }
    }
}
