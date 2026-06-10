public with sharing class OpportunitySelector extends ApplicationSelector {

    private static OpportunitySelector instance;

    public static OpportunitySelector getInstance() {
        if (instance == null) {
            instance = new OpportunitySelector();
        }
        return instance;
    }

    public override Schema.SObjectType getSObjectType() {
        return Opportunity.SObjectType;
    }

    public override List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Opportunity.Id,
            Opportunity.Name,
            Opportunity.AccountId,
            Opportunity.Amount,
            Opportunity.CloseDate,
            Opportunity.StageName,
            Opportunity.OwnerId
        };
    }

    public List<Opportunity> selectById(Set<Id> ids) {
        assertIsAccessible();
        return [
            SELECT Id, Name, AccountId, Amount, CloseDate, StageName, OwnerId
            FROM Opportunity
            WHERE Id IN :ids
        ];
    }

    // Retorna registro único — null se não encontrado
    public Opportunity selectSingleById(Id oppId) {
        assertIsAccessible();
        List<Opportunity> results = [
            SELECT Id, Name, AccountId, Amount, CloseDate, StageName, OwnerId
            FROM Opportunity
            WHERE Id = :oppId
            LIMIT 1
        ];
        return results.isEmpty() ? null : results[0];
    }

    public List<Opportunity> selectClosedWonByAccountIds(Set<Id> accountIds) {
        assertIsAccessible();
        return [
            SELECT AccountId, CloseDate, StageName
            FROM Opportunity
            WHERE AccountId IN :accountIds
              AND StageName = 'Closed Won'
            ORDER BY CloseDate DESC
        ];
    }
}
