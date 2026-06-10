public class BatchScheduler {

    // Cron expressions (formato Salesforce: segundos minutos horas dia-mês mês dia-semana)
    private static final String CRON_MIDNIGHT   = '0 0 0 * * ?';
    private static final String CRON_1AM        = '0 0 1 * * ?';
    private static final String CRON_2AM        = '0 0 2 * * ?';
    private static final String CRON_1ST_8AM    = '0 0 8 1 * ?';
    private static final String CRON_MON_7AM    = '0 0 7 ? * MON';
    private static final String CRON_MON_9AM    = '0 0 9 ? * MON';

    // Agenda todos os jobs — executar via Anonymous Apex após deploy
    public static void scheduleAll() {
        scheduleProposalExpiration();
        scheduleLeadCleanup();
        scheduleCustomerHealth();
        scheduleCommissionSummary();
        scheduleAIInsights();
        scheduleContractRenewal();
    }

    // Diário à meia-noite: expira propostas com prazo vencido
    public static void scheduleProposalExpiration() {
        schedule('ProposalExpirationBatch', CRON_MIDNIGHT, new ProposalExpirationBatch());
    }

    // Diário às 01:00: inativa leads sem atividade há 90+ dias
    public static void scheduleLeadCleanup() {
        schedule('LeadCleanupBatch', CRON_1AM, new LeadCleanupBatch());
    }

    // Diário às 02:00: recalcula health score de todas as contas
    public static void scheduleCustomerHealth() {
        schedule('CustomerHealthBatch', CRON_2AM, new CustomerHealthBatch());
    }

    // Dia 1 de cada mês às 08:00: consolida comissões pendentes
    public static void scheduleCommissionSummary() {
        schedule('CommissionSummaryBatch', CRON_1ST_8AM, new CommissionSummaryBatch());
    }

    // Toda segunda às 07:00: gera insights de IA para health records sem análise
    public static void scheduleAIInsights() {
        schedule('AIInsightBatch', CRON_MON_7AM, new AIInsightBatch());
    }

    // Toda segunda às 09:00: alerta contratos vencendo em 30 dias
    public static void scheduleContractRenewal() {
        schedule('ContractRenewalScheduled', CRON_MON_9AM, new ContractRenewalScheduled());
    }

    // Aborta todos os jobs gerenciados por este scheduler
    public static void abortAll() {
        String[] jobs = new String[]{
            'ProposalExpirationBatch', 'LeadCleanupBatch', 'CustomerHealthBatch',
            'CommissionSummaryBatch',  'AIInsightBatch',   'ContractRenewalScheduled'
        };
        for (String jobName : jobs) {
            abortIfExists(jobName);
        }
    }

    public static void abortIfExists(String jobName) {
        for (CronTrigger ct : [
            SELECT Id FROM CronTrigger
            WHERE CronJobDetail.Name = :jobName
        ]) {
            System.abortJob(ct.Id);
        }
    }

    private static void schedule(String jobName, String cronExpr, Schedulable job) {
        abortIfExists(jobName);
        System.schedule(jobName, cronExpr, job);
    }
}
