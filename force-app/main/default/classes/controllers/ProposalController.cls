public with sharing class ProposalController {

    @AuraEnabled(cacheable=true)
    public static List<Product_Proposal__c> getProposalsByOpportunity(Id opportunityId) {
        return [
            SELECT Id, Name, Status__c, Total_Value__c, Final_Value__c,
                   Discount_Percentage__c, Valid_Until__c, Sent_Date__c, AI_Summary__c
            FROM Product_Proposal__c
            WHERE Opportunity__c = :opportunityId
            ORDER BY CreatedDate DESC
        ];
    }

    @AuraEnabled
    public static Id createProposal(Id opportunityId) {
        return ProposalService.createProposal(opportunityId);
    }

    @AuraEnabled
    public static void sendProposal(Id proposalId) {
        ProposalService.sendProposal(proposalId);
    }

    @AuraEnabled
    public static void updateStatus(Id proposalId, String status) {
        update new Product_Proposal__c(Id = proposalId, Status__c = status);
    }
}
