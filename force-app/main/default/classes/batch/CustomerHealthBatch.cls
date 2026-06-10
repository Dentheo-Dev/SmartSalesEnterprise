public with sharing class CustomerHealthBatch implements Database.Batchable<SObject>, Schedulable {

    // Permite agendar o batch diretamente via System.schedule()
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new CustomerHealthBatch(), 100);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id FROM Account');
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        List<Id> accountIds = new List<Id>();
        for (Account acc : scope) {
            accountIds.add(acc.Id);
        }
        CustomerHealthService.calculateHealth(accountIds);
    }

    public void finish(Database.BatchableContext bc) {
        // Health scores recalculados para todas as contas
    }
}
