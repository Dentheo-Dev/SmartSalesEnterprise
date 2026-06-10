public with sharing class ProposalExpirationBatch implements Database.Batchable<SObject>, Schedulable {

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new ProposalExpirationBatch(), 200);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Status__c
            FROM Product_Proposal__c
            WHERE Status__c = 'Enviada'
              AND Valid_Until__c < TODAY
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Product_Proposal__c> scope) {
        for (Product_Proposal__c p : scope) {
            p.Status__c = 'Expirada';
        }
        Database.update(scope, false);
    }

    public void finish(Database.BatchableContext bc) {
        // Propostas com prazo vencido marcadas como Expirada
    }
}
