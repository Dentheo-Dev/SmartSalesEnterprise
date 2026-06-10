@IsTest
private class ProposalExpirationBatchTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Proposal Batch Corp');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Opp Proposals', AccountId = acc.Id,
            Amount = 30000, StageName = 'Proposal/Price Quote',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        insert new List<Product_Proposal__c>{
            new Product_Proposal__c(
                Name = 'PROP-EXP-001', Opportunity__c = opp.Id, Account__c = acc.Id,
                Total_Value__c = 30000, Discount_Percentage__c = 0,
                Status__c = 'Enviada', Valid_Until__c = Date.today().addDays(-1)
            ),
            new Product_Proposal__c(
                Name = 'PROP-EXP-002', Opportunity__c = opp.Id, Account__c = acc.Id,
                Total_Value__c = 30000, Discount_Percentage__c = 5,
                Status__c = 'Enviada', Valid_Until__c = Date.today().addDays(-5)
            ),
            new Product_Proposal__c(
                Name = 'PROP-VALID', Opportunity__c = opp.Id, Account__c = acc.Id,
                Total_Value__c = 30000, Discount_Percentage__c = 0,
                Status__c = 'Enviada', Valid_Until__c = Date.today().addDays(15)
            )
        };
    }

    @IsTest
    static void testBatchExpiraPropostas() {
        Test.startTest();
        Database.executeBatch(new ProposalExpirationBatch(), 200);
        Test.stopTest();

        Integer expiradas = [SELECT COUNT() FROM Product_Proposal__c WHERE Status__c = 'Expirada'];
        System.assertEquals(2, expiradas, 'Deve expirar 2 propostas com prazo vencido');

        Integer enviadas = [SELECT COUNT() FROM Product_Proposal__c WHERE Status__c = 'Enviada'];
        System.assertEquals(1, enviadas, 'Proposta com prazo válido deve permanecer Enviada');
    }

    @IsTest
    static void testBatchSemPropostasVencidas() {
        delete [SELECT Id FROM Product_Proposal__c WHERE Valid_Until__c < TODAY];

        Test.startTest();
        Database.executeBatch(new ProposalExpirationBatch(), 200);
        Test.stopTest();

        System.assert(true, 'Batch sem propostas vencidas deve completar sem erro');
    }

    @IsTest
    static void testSchedulable() {
        Test.startTest();
        String jobId = System.schedule('TestProposalExpBatch', '0 0 0 * * ?', new ProposalExpirationBatch());
        Test.stopTest();

        CronTrigger ct = [SELECT Id, CronExpression FROM CronTrigger WHERE Id = :jobId];
        System.assertNotEquals(null, ct.Id);
        System.assertEquals('0 0 0 * * ?', ct.CronExpression);
    }
}
