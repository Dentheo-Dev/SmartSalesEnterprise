public with sharing class CaseSelector extends ApplicationSelector {

    private static CaseSelector instance;

    public static CaseSelector getInstance() {
        if (instance == null) {
            instance = new CaseSelector();
        }
        return instance;
    }

    public override Schema.SObjectType getSObjectType() {
        return Case.SObjectType;
    }

    public override List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Case.Id,
            Case.AccountId,
            Case.Subject,
            Case.Status,
            Case.Priority
        };
    }

    public List<Case> selectById(Set<Id> ids) {
        assertIsAccessible();
        return [
            SELECT Id, AccountId, Subject, Status, Priority, IsClosed
            FROM Case
            WHERE Id IN :ids
        ];
    }

    public List<AggregateResult> selectOpenCasesCountByAccountIds(Set<Id> accountIds) {
        assertIsAccessible();
        return [
            SELECT AccountId, COUNT(Id) total
            FROM Case
            WHERE AccountId IN :accountIds
              AND IsClosed = false
            GROUP BY AccountId
        ];
    }
}
