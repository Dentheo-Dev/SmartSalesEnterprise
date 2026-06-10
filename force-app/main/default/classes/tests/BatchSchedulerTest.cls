@IsTest
private class BatchSchedulerTest {

    private static final List<String> JOB_NAMES = new List<String>{
        'ProposalExpirationBatch', 'LeadCleanupBatch', 'CustomerHealthBatch',
        'CommissionSummaryBatch',  'AIInsightBatch',   'ContractRenewalScheduled'
    };

    @IsTest
    static void testScheduleAll() {
        Test.startTest();
        BatchScheduler.scheduleAll();
        Test.stopTest();

        Integer jobCount = [
            SELECT COUNT() FROM CronTrigger
            WHERE CronJobDetail.Name IN :JOB_NAMES
        ];
        System.assertEquals(6, jobCount, 'Todos os 6 jobs devem estar agendados');
    }

    @IsTest
    static void testAbortAll() {
        BatchScheduler.scheduleAll();

        Test.startTest();
        BatchScheduler.abortAll();
        Test.stopTest();

        Integer jobCount = [
            SELECT COUNT() FROM CronTrigger
            WHERE CronJobDetail.Name IN :JOB_NAMES
        ];
        System.assertEquals(0, jobCount, 'Todos os jobs devem ter sido abortados');
    }

    @IsTest
    static void testAbortIfExistsJobInexistente() {
        Test.startTest();
        BatchScheduler.abortIfExists('JobQueNaoExiste_' + System.currentTimeMillis());
        Test.stopTest();

        System.assert(true, 'abortIfExists deve ser idempotente para job inexistente');
    }

    @IsTest
    static void testScheduleIndividual() {
        Test.startTest();
        BatchScheduler.scheduleProposalExpiration();
        BatchScheduler.scheduleLeadCleanup();
        BatchScheduler.scheduleCustomerHealth();
        BatchScheduler.scheduleCommissionSummary();
        BatchScheduler.scheduleAIInsights();
        BatchScheduler.scheduleContractRenewal();
        Test.stopTest();

        Integer jobCount = [
            SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name IN :JOB_NAMES
        ];
        System.assertEquals(6, jobCount, 'Agendamentos individuais devem resultar em 6 jobs');
    }

    @IsTest
    static void testReagendarJobExistente() {
        // Deve abortar e reagendar sem lançar exceção
        BatchScheduler.scheduleCustomerHealth();

        Test.startTest();
        BatchScheduler.scheduleCustomerHealth();
        Test.stopTest();

        Integer jobCount = [
            SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name = 'CustomerHealthBatch'
        ];
        System.assertEquals(1, jobCount, 'Deve existir apenas um CustomerHealthBatch agendado');
    }
}
