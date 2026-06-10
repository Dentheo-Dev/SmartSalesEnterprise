@IsTest
private class CustomerHealthControllerTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Health Controller Corp');
        insert acc;

        insert new Customer_Health__c(
            Account__c            = acc.Id,
            Name                  = 'Health Score',
            Health_Score__c       = 75,
            Health_Status__c      = 'Saudável',
            NPS_Score__c          = 8,
            Open_Cases__c         = 1,
            Last_Purchase_Days__c = 30,
            Payment_Delays__c     = 0,
            Last_Calculated__c    = Datetime.now()
        );
    }

    @IsTest
    static void testGetHealthRecord() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Health Controller Corp'];

        Test.startTest();
        Customer_Health__c result = CustomerHealthController.getHealthRecord(acc.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Deve retornar o registro');
        System.assertEquals(75, result.Health_Score__c, 'Score deve ser 75');
        System.assertEquals('Saudável', result.Health_Status__c, 'Status deve ser Saudável');
    }

    @IsTest
    static void testGetHealthRecordSemRegistro() {
        Account acc = new Account(Name = 'Sem Health Corp');
        insert acc;

        Test.startTest();
        Customer_Health__c result = CustomerHealthController.getHealthRecord(acc.Id);
        Test.stopTest();

        System.assertEquals(null, result, 'Deve retornar null quando não há registro');
    }

    @IsTest
    static void testRecalculate() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Health Controller Corp'];

        Test.startTest();
        CustomerHealthController.recalculate(acc.Id);
        Test.stopTest();

        Customer_Health__c result = [
            SELECT Health_Score__c, Last_Calculated__c
            FROM Customer_Health__c
            WHERE Account__c = :acc.Id
        ];
        System.assertNotEquals(null, result.Last_Calculated__c, 'Deve ter data de cálculo');
    }

    @IsTest
    static void testGetHealthRecordRetornaUltimoRegistro() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Health Controller Corp'];

        // Inserir segundo registro mais recente
        insert new Customer_Health__c(
            Account__c      = acc.Id,
            Name            = 'Health Score 2',
            Health_Score__c = 90,
            Health_Status__c = 'Excelente'
        );

        Test.startTest();
        Customer_Health__c result = CustomerHealthController.getHealthRecord(acc.Id);
        Test.stopTest();

        System.assertEquals(90, result.Health_Score__c, 'Deve retornar o registro mais recente (score=90)');
    }
}
