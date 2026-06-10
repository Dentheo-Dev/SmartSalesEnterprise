public with sharing class LeadCleanupBatch implements Database.Batchable<SObject>, Schedulable {

    private static final Integer DIAS_INATIVO = 90;

    @TestVisible
    private Datetime cutoffDatetime;

    public LeadCleanupBatch() {
        this.cutoffDatetime = Datetime.now().addDays(-DIAS_INATIVO);
    }

    @TestVisible
    private LeadCleanupBatch(Datetime cutoffDatetime) {
        this.cutoffDatetime = cutoffDatetime;
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new LeadCleanupBatch(), 200);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Status, Score_Reason__c
            FROM Lead
            WHERE IsConverted = false
              AND Status != 'Closed - Not Converted'
              AND LastModifiedDate < :cutoffDatetime
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Lead> scope) {
        for (Lead lead : scope) {
            lead.Status          = 'Closed - Not Converted';
            lead.Score_Reason__c = 'Inativado automaticamente: sem atividade há mais de '
                                   + DIAS_INATIVO + ' dias.';
        }
        Database.update(scope, false);
    }

    public void finish(Database.BatchableContext bc) {
        // Leads inativos marcados como Closed - Not Converted
    }
}
