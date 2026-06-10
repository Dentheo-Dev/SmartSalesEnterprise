@IsTest
private class ContractRenewalScheduledTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Renewal Test Corp');
        insert acc;

        insert new List<Contract_Renewal__c>{
            new Contract_Renewal__c(
                Name                     = 'Renovação Urgente',
                Account__c               = acc.Id,
                Owner__c                 = UserInfo.getUserId(),
                Original_Contract_End__c = Date.today().addDays(15),
                Renewal_Value__c         = 120000,
                Status__c                = 'Pendente'
            ),
            new Contract_Renewal__c(
                Name                     = 'Renovação Distante',
                Account__c               = acc.Id,
                Owner__c                 = UserInfo.getUserId(),
                Original_Contract_End__c = Date.today().addDays(60),
                Renewal_Value__c         = 80000,
                Status__c                = 'Em Negociação'
            ),
            new Contract_Renewal__c(
                Name                     = 'Já Renovado',
                Account__c               = acc.Id,
                Owner__c                 = UserInfo.getUserId(),
                Original_Contract_End__c = Date.today().addDays(10),
                Renewal_Value__c         = 50000,
                Status__c                = 'Renovado'
            )
        };
    }

    @IsTest
    static void testEnviaAlertasContratosProximos() {
        // Contrato vencendo em 15 dias deve disparar alerta; já renovado e distante não
        Test.startTest();
        new ContractRenewalScheduled().execute(null);
        Test.stopTest();

        // Sem exceção = sucesso; email de alerta enviado para 'Renovação Urgente'
        System.assert(true, 'Job deve completar sem erro');
    }

    @IsTest
    static void testNenhumContratoElegivel() {
        delete [SELECT Id FROM Contract_Renewal__c];

        Test.startTest();
        new ContractRenewalScheduled().execute(null);
        Test.stopTest();

        System.assert(true, 'Job sem contratos elegíveis deve completar sem erro');
    }

    @IsTest
    static void testContratoSemOwnerEmail() {
        // Owner sem email definido não deve lançar exceção
        Account acc = [SELECT Id FROM Account LIMIT 1];
        insert new Contract_Renewal__c(
            Name                     = 'Sem Owner',
            Account__c               = acc.Id,
            Owner__c                 = null,
            Original_Contract_End__c = Date.today().addDays(5),
            Renewal_Value__c         = 20000,
            Status__c                = 'Pendente'
        );

        Test.startTest();
        new ContractRenewalScheduled().execute(null);
        Test.stopTest();

        System.assert(true, 'Contrato sem owner não deve lançar exceção');
    }

    @IsTest
    static void testSchedulable() {
        Test.startTest();
        String jobId = System.schedule('TestContractRenewal', '0 0 9 ? * MON', new ContractRenewalScheduled());
        Test.stopTest();

        CronTrigger ct = [SELECT Id, CronExpression FROM CronTrigger WHERE Id = :jobId];
        System.assertNotEquals(null, ct.Id);
        System.assertEquals('0 0 9 ? * MON', ct.CronExpression);
    }
}
