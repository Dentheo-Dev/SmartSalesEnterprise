public with sharing class AIInsightBatch implements Database.Batchable<SObject>, Database.AllowsCallouts, Schedulable {

    // Escopo pequeno para respeitar limites de callout do OpenAI por transação
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new AIInsightBatch(), 10);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // AI_Health_Analysis__c é Long Text Area: não filtrável em SOQL
        return Database.getQueryLocator([
            SELECT Id, AI_Health_Analysis__c
            FROM Customer_Health__c
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Customer_Health__c> scope) {
        for (Customer_Health__c h : scope) {
            if (String.isNotBlank(h.AI_Health_Analysis__c)) {
                continue; // Já possui análise — não reprocessar
            }
            try {
                AIInsightService.enrichHealthAnalysis(h.Id);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR,
                    'AIInsightBatch: erro ao enriquecer health ' + h.Id + ' — ' + e.getMessage());
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        // Insights de IA gerados para health records sem análise
    }
}
