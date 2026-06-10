public with sharing class LeadSelector extends ApplicationSelector {

    private static LeadSelector instance;

    public static LeadSelector getInstance() {
        if (instance == null) {
            instance = new LeadSelector();
        }
        return instance;
    }

    public override Schema.SObjectType getSObjectType() {
        return Lead.SObjectType;
    }

    public override List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Lead.Id,
            Lead.FirstName,
            Lead.LastName,
            Lead.Email,
            Lead.Phone,
            Lead.Company,
            Lead.Status
        };
    }

    public List<Lead> selectById(Set<Id> ids) {
        assertIsAccessible();
        return [
            SELECT Id, FirstName, LastName, Email, Phone, Company, Status,
                   Lead_Score__c, Score_Reason__c, Company_Size__c,
                   Annual_Revenue_Estimate__c, Title, LeadSource, OwnerId
            FROM Lead
            WHERE Id IN :ids
        ];
    }

    public List<Lead> selectByStatus(String status) {
        assertIsAccessible();
        return [
            SELECT Id, FirstName, LastName, Email, Phone, Company,
                   Status, Lead_Score__c, OwnerId
            FROM Lead
            WHERE Status = :status
        ];
    }

    // Leads não convertidos com score mínimo, ordenados por score decrescente
    public List<Lead> selectUnconvertedByMinScore(Decimal minScore) {
        assertIsAccessible();
        return [
            SELECT Id, FirstName, LastName, Email, Company,
                   Lead_Score__c, Score_Reason__c, OwnerId
            FROM Lead
            WHERE IsConverted = false
              AND Lead_Score__c >= :minScore
            ORDER BY Lead_Score__c DESC
        ];
    }
}
