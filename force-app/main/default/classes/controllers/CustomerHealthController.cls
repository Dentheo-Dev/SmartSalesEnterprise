public with sharing class CustomerHealthController {

    @AuraEnabled(cacheable=true)
    public static Customer_Health__c getHealthRecord(Id accountId) {
        List<Customer_Health__c> records = [
            SELECT Id, Account__c, Health_Score__c, Health_Status__c,
                   Open_Cases__c, NPS_Score__c, Last_Purchase_Days__c,
                   Payment_Delays__c, Last_Calculated__c, AI_Health_Analysis__c
            FROM Customer_Health__c
            WHERE Account__c = :accountId
            ORDER BY CreatedDate DESC, Id DESC
            LIMIT 1
        ];
        return records.isEmpty() ? null : records[0];
    }

    @AuraEnabled
    public static void recalculate(Id accountId) {
        CustomerHealthService.calculateHealth(new List<Id>{ accountId });
    }
}
