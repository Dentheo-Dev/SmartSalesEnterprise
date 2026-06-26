@IsTest
private class LeadCleanupBatchTest {

    @TestSetup
    static void setup() {
        insert new List<Lead>{
            new Lead(FirstName = 'Lead', LastName = 'Ativo',    Company = 'Empresa A', Status = 'Open - Not Contacted'),
            new Lead(FirstName = 'Lead', LastName = 'Working',  Company = 'Empresa B', Status = 'Working - Contacted'),
            new Lead(FirstName = 'Lead', LastName = 'Fechado',  Company = 'Empresa C', Status = 'Closed - Not Converted')
        };
    }

    @IsTest
    static void testBatchMarcaLeadsInativos() {
        // cutoffDatetime = amanhã → captura todos os leads recém-criados
        Test.startTest();
        Database.executeBatch(new LeadCleanupBatch(Datetime.now().addDays(1)), 200);
        Test.stopTest();

        // Lead 'Ativo' e 'Working' fechados + 'Fechado' que já era = 3
        Integer fechados = [SELECT COUNT() FROM Lead WHERE Status = 'Closed - Not Converted'];
        System.assertEquals(3, fechados, 'Todos os leads devem estar como Closed - Not Converted');
    }

    @IsTest
    static void testBatchSemLeadsElegiveis() {
        // cutoffDatetime no passado distante → nenhum lead recém-criado é capturado
        Test.startTest();
        Database.executeBatch(new LeadCleanupBatch(Datetime.now().addDays(-180)), 200);
        Test.stopTest();

        Integer fechados = [SELECT COUNT() FROM Lead WHERE Status = 'Closed - Not Converted'];
        System.assertEquals(0, fechados, 'Nenhum lead deve ser fechado quando o cutoff está no passado');
    }

    @IsTest
    static void testBatchPreencheScoreReason() {
        Test.startTest();
        Database.executeBatch(new LeadCleanupBatch(Datetime.now().addDays(1)), 200);
        Test.stopTest();

        List<Lead> atualizados = [
            SELECT Score_Reason__c FROM Lead
            WHERE Status = 'Closed - Not Converted'
              AND Score_Reason__c != null
              AND Score_Reason__c LIKE 'Inativado automaticamente%'
        ];
        System.assert(!atualizados.isEmpty(), 'Score_Reason__c deve ter mensagem de inativação');
    }

    @IsTest
    static void testSchedulable() {
        Test.startTest();
        String jobId = System.schedule('TestLeadCleanupBatch', '0 0 1 * * ?', new LeadCleanupBatch());
        Test.stopTest();

        CronTrigger ct = [SELECT Id, CronExpression FROM CronTrigger WHERE Id = :jobId];
        System.assertNotEquals(null, ct.Id);
        System.assertEquals('0 0 1 * * ?', ct.CronExpression);
    }
}
