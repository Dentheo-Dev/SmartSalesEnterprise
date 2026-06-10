@IsTest
private class CustomerHealthBatchTest {

    @TestSetup
    static void setup() {
        insert new List<Account>{
            new Account(Name = 'Health Batch Corp A'),
            new Account(Name = 'Health Batch Corp B'),
            new Account(Name = 'Health Batch Corp C')
        };
    }

    @IsTest
    static void testBatchCriaHealthRecords() {
        List<Account> accounts = [SELECT Id FROM Account];

        Test.startTest();
        Database.executeBatch(new CustomerHealthBatch(), 200);
        Test.stopTest();

        Integer count = [SELECT COUNT() FROM Customer_Health__c];
        System.assertEquals(accounts.size(), count, 'Deve criar um Customer_Health__c por account');
    }

    @IsTest
    static void testBatchAtualizaHealthExistente() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Health Batch Corp A' LIMIT 1];
        insert new Customer_Health__c(
            Name = 'Health Score', Account__c = acc.Id,
            Health_Score__c = 50, Health_Status__c = 'Em Risco'
        );

        Test.startTest();
        Database.executeBatch(new CustomerHealthBatch(), 200);
        Test.stopTest();

        Integer count = [SELECT COUNT() FROM Customer_Health__c WHERE Account__c = :acc.Id];
        System.assertEquals(1, count, 'Upsert não deve criar duplicata para o mesmo account');
    }

    @IsTest
    static void testSchedulable() {
        Test.startTest();
        String jobId = System.schedule('TestCustomerHealthBatch', '0 0 2 * * ?', new CustomerHealthBatch());
        Test.stopTest();

        CronTrigger ct = [SELECT Id, CronExpression FROM CronTrigger WHERE Id = :jobId];
        System.assertNotEquals(null, ct.Id, 'Job deve estar agendado');
        System.assertEquals('0 0 2 * * ?', ct.CronExpression, 'Cron expression deve ser a diária das 2h');
    }

    @IsTest
    static void testBatchSemAccounts() {
        delete [SELECT Id FROM Account];

        Test.startTest();
        Database.executeBatch(new CustomerHealthBatch(), 200);
        Test.stopTest();

        System.assert(true, 'Batch sem accounts deve completar sem erro');
    }
}
