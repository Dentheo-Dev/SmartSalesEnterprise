public with sharing class ProductProposalSelector extends ApplicationSelector {

    private static ProductProposalSelector instance;

    public static ProductProposalSelector getInstance() {
        if (instance == null) {
            instance = new ProductProposalSelector();
        }
        return instance;
    }

    public override Schema.SObjectType getSObjectType() {
        return Product_Proposal__c.SObjectType;
    }

    public override List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Product_Proposal__c.Id,
            Product_Proposal__c.Name,
            Product_Proposal__c.Status__c,
            Product_Proposal__c.Opportunity__c,
            Product_Proposal__c.Account__c,
            Product_Proposal__c.Total_Value__c
        };
    }

    // Busca proposta com relacionamentos para envio e notificação
    public Product_Proposal__c selectById(Id proposalId) {
        assertIsAccessible();
        return [
            SELECT Id, Status__c, Sent_Date__c, Discount_Percentage__c,
                   Total_Value__c, Final_Value__c,
                   Account__r.Name,
                   Opportunity__r.Owner.Email, Opportunity__r.Owner.Name
            FROM Product_Proposal__c
            WHERE Id = :proposalId
            LIMIT 1
        ];
    }

    public List<Product_Proposal__c> selectExpiredSent() {
        assertIsAccessible();
        return [
            SELECT Id, Status__c
            FROM Product_Proposal__c
            WHERE Status__c = 'Enviada'
              AND Valid_Until__c < TODAY
        ];
    }
}
