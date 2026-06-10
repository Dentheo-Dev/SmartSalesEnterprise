public with sharing class CommissionSelector extends ApplicationSelector {

    private static CommissionSelector instance;

    public static CommissionSelector getInstance() {
        if (instance == null) {
            instance = new CommissionSelector();
        }
        return instance;
    }

    public override Schema.SObjectType getSObjectType() {
        return Commission__c.SObjectType;
    }

    public override List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Commission__c.Id,
            Commission__c.Opportunity__c,
            Commission__c.Commission_Rate__c,
            Commission__c.Commission_Amount__c,
            Commission__c.Status__c
        };
    }

    // Retorna mapa Opportunity ID → Commission__c para evitar queries duplicadas no cálculo
    public Map<Id, Commission__c> selectByOpportunityIds(Set<Id> opportunityIds) {
        assertIsAccessible();
        Map<Id, Commission__c> result = new Map<Id, Commission__c>();
        for (Commission__c c : [
            SELECT Id, Opportunity__c
            FROM Commission__c
            WHERE Opportunity__c IN :opportunityIds
        ]) {
            result.put(c.Opportunity__c, c);
        }
        return result;
    }
}
