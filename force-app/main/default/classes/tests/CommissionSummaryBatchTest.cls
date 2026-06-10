@IsTest
private class CommissionSummaryBatchTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Commission Batch Corp');
        insert acc;

        List<Opportunity> opps = new List<Opportunity>{
            new Opportunity(
                Name = 'Opp Batch 1', AccountId = acc.Id,
                Amount = 15000, StageName = 'Closed Won',
                CloseDate = Date.today().addDays(30)
            ),
            new Opportunity(
                Name = 'Opp Batch 2', AccountId = acc.Id,
                Amount = 80000, StageName = 'Closed Won',
                CloseDate = Date.today().addDays(30)
            )
        };
        insert opps;

        // Trigger afterInsert seta Commission_Calculated__c = true automaticamente.
        // Reset para simular oportunidades com comissão pendente de reprocessamento.
        List<Id> ids = new List<Id>();
        for (Opportunity o : opps) { ids.add(o.Id); }
        List<Opportunity> toReset = [SELECT Id FROM Opportunity WHERE Id IN :ids];
        for (Opportunity o : toReset) { o.Commission_Calculated__c = false; }
        update toReset;
    }

    @IsTest
    static void testBatchProcessaComissoesPendentes() {
        Test.startTest();
        Database.executeBatch(new CommissionSummaryBatch(), 100);
        Test.stopTest();

        Integer comissoes = [SELECT COUNT() FROM Commission__c];
        System.assertEquals(2, comissoes, 'Deve ter 2 registros Commission__c');

        Integer flagged = [
            SELECT COUNT() FROM Opportunity WHERE Commission_Calculated__c = true
        ];
        System.assertEquals(2, flagged, 'Ambas as oportunidades devem ter Commission_Calculated__c = true');
    }

    @IsTest
    static void testBatchSemPendentes() {
        // Garante que não há pendentes
        List<Opportunity> opps = [SELECT Id FROM Opportunity];
        for (Opportunity o : opps) {
            o.Commission_Calculated__c = true;
        }
        update opps;

        Test.startTest();
        Database.executeBatch(new CommissionSummaryBatch(), 100);
        Test.stopTest();

        System.assert(true, 'Batch sem pendentes deve completar sem erro');
    }

    @IsTest
    static void testSchedulable() {
        Test.startTest();
        String jobId = System.schedule('TestCommissionBatch', '0 0 8 1 * ?', new CommissionSummaryBatch());
        Test.stopTest();

        CronTrigger ct = [SELECT Id, CronExpression FROM CronTrigger WHERE Id = :jobId];
        System.assertNotEquals(null, ct.Id);
    }
}
