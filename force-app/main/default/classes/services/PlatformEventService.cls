public with sharing class PlatformEventService {

    public static void publishLeadScored(
        Id leadId, Decimal score, Decimal previousScore, String reason
    ) {
        publish(new Lead_Scored__e(
            Lead_Id__c        = String.valueOf(leadId),
            Score__c          = score,
            Previous_Score__c = previousScore,
            Score_Reason__c   = reason
        ));
    }

    public static void publishOpportunityStageChanged(
        Id oppId, String previousStage, String newStage, Decimal amount
    ) {
        publish(new Opportunity_Stage_Changed__e(
            Opportunity_Id__c = String.valueOf(oppId),
            Previous_Stage__c = previousStage,
            New_Stage__c      = newStage,
            Amount__c         = amount
        ));
    }

    public static void publishCustomerHealthAlert(
        Id accountId, String accountName,
        Decimal healthScore, String healthStatus, String previousStatus
    ) {
        publish(new Customer_Health_Alert__e(
            Account_Id__c      = String.valueOf(accountId),
            Account_Name__c    = accountName,
            Health_Score__c    = healthScore,
            Health_Status__c   = healthStatus,
            Previous_Status__c = previousStatus
        ));
    }

    public static void publishContractRenewalAlert(
        Id contractRenewalId, Id accountId, String accountName,
        Integer daysUntilExpiration, Decimal renewalValue
    ) {
        publish(new Contract_Renewal_Alert__e(
            Contract_Renewal_Id__c   = String.valueOf(contractRenewalId),
            Account_Id__c            = String.valueOf(accountId),
            Account_Name__c          = accountName,
            Days_Until_Expiration__c = daysUntilExpiration,
            Renewal_Value__c         = renewalValue
        ));
    }

    // Publicação em lote — preferir sobre chamadas individuais em contextos bulk
    public static void publishAll(List<SObject> events) {
        if (events == null || events.isEmpty()) {
            return;
        }
        List<Database.SaveResult> results = EventBus.publish(events);
        for (Database.SaveResult sr : results) {
            if (!sr.isSuccess()) {
                System.debug(LoggingLevel.ERROR,
                    'PlatformEventService: falha ao publicar evento — '
                    + JSON.serialize(sr.getErrors()));
            }
        }
    }

    private static void publish(SObject event) {
        publishAll(new List<SObject>{ event });
    }
}
