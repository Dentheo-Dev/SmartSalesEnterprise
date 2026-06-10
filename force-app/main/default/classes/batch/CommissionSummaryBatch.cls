public with sharing class CommissionSummaryBatch implements Database.Batchable<SObject>, Schedulable {

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new CommissionSummaryBatch(), 100);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, Amount, AccountId, CloseDate, StageName, OwnerId,
                   Commission_Calculated__c
            FROM Opportunity
            WHERE StageName = 'Closed Won'
              AND Commission_Calculated__c = false
              AND Amount != null
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        CommissionCalculatorService.calculateCommission(scope);
    }

    public void finish(Database.BatchableContext bc) {
        // Comissões calculadas para todas as oportunidades Closed Won pendentes
    }
}
