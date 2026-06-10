public with sharing class CustomerHealthSelector extends ApplicationSelector {

    private static CustomerHealthSelector instance;

    public static CustomerHealthSelector getInstance() {
        if (instance == null) {
            instance = new CustomerHealthSelector();
        }
        return instance;
    }

    public override Schema.SObjectType getSObjectType() {
        return Customer_Health__c.SObjectType;
    }

    public override List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Customer_Health__c.Id,
            Customer_Health__c.Account__c,
            Customer_Health__c.Health_Score__c,
            Customer_Health__c.Health_Status__c
        };
    }

    // Retorna o registro mais recente por account (um por account ID)
    public Map<Id, Customer_Health__c> selectLatestByAccountIds(Set<Id> accountIds) {
        assertIsAccessible();
        Map<Id, Customer_Health__c> result = new Map<Id, Customer_Health__c>();
        for (Customer_Health__c ch : [
            SELECT Id, Account__c, Open_Cases__c, NPS_Score__c,
                   Payment_Delays__c, Last_Purchase_Days__c
            FROM Customer_Health__c
            WHERE Account__c IN :accountIds
            ORDER BY CreatedDate DESC
        ]) {
            if (!result.containsKey(ch.Account__c)) {
                result.put(ch.Account__c, ch);
            }
        }
        return result;
    }
}
