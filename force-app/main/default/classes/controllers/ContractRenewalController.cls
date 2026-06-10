public with sharing class ContractRenewalController {

    @AuraEnabled(cacheable=true)
    public static List<Contract_Renewal__c> getExpiringContracts(Integer daysThreshold) {
        if (daysThreshold == null || daysThreshold <= 0) {
            daysThreshold = 90;
        }
        Date cutoff = Date.today().addDays(daysThreshold);
        return [
            SELECT Id, Name, Account__c, Account__r.Name,
                   Original_Contract_End__c, Renewal_Value__c,
                   Status__c, Days_Until_Expiration__c, Renewal_Probability__c
            FROM Contract_Renewal__c
            WHERE Original_Contract_End__c <= :cutoff
              AND Original_Contract_End__c >= TODAY
              AND Status__c != 'Renovado'
            ORDER BY Original_Contract_End__c ASC
            LIMIT 100
        ];
    }
}
