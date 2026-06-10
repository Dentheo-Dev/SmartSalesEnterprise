public class CaseTriggerHandler extends TriggerHandler {

    private List<Case> newList;
    private List<Case> oldList;
    private Map<Id, Case> newMap;
    private Map<Id, Case> oldMap;

    public CaseTriggerHandler() {
        this.newList = (List<Case>) Trigger.new;
        this.oldList = (List<Case>) Trigger.old;
        this.newMap  = (Map<Id, Case>) Trigger.newMap;
        this.oldMap  = (Map<Id, Case>) Trigger.oldMap;
    }

    override protected void afterInsert() {
        updateOpenCaseCount(newList);
        createUrgentTasksForHighPriority(newList);
    }

    override protected void afterUpdate() {
        List<Case> closedCases = new List<Case>();

        for (Case c : newList) {
            Case old = oldMap.get(c.Id);
            if (c.Status == 'Closed' && old.Status != 'Closed') {
                closedCases.add(c);
            }
        }

        if (!closedCases.isEmpty()) {
            triggerHealthRecalculation(closedCases);
        }
    }

    // Incrementa Open_Cases__c no Customer_Health__c da Account
    private static void updateOpenCaseCount(List<Case> cases) {
        Set<Id> accountIds = new Set<Id>();
        for (Case c : cases) {
            if (c.AccountId != null) {
                accountIds.add(c.AccountId);
            }
        }

        if (accountIds.isEmpty()) {
            return;
        }

        Map<Id, Customer_Health__c> healthByAccount = new Map<Id, Customer_Health__c>();
        for (Customer_Health__c ch : [
            SELECT Id, Account__c, Open_Cases__c
            FROM Customer_Health__c
            WHERE Account__c IN :accountIds
        ]) {
            healthByAccount.put(ch.Account__c, ch);
        }

        List<Customer_Health__c> toUpdate = new List<Customer_Health__c>();
        for (Id accId : accountIds) {
            if (healthByAccount.containsKey(accId)) {
                Customer_Health__c ch = healthByAccount.get(accId);
                ch.Open_Cases__c = (ch.Open_Cases__c == null ? 0 : ch.Open_Cases__c) + 1;
                toUpdate.add(ch);
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    // Cria Task urgente para o dono da Account quando case é High priority
    private static void createUrgentTasksForHighPriority(List<Case> cases) {
        Set<Id> accountIds = new Set<Id>();
        for (Case c : cases) {
            if (c.Priority == 'High' && c.AccountId != null) {
                accountIds.add(c.AccountId);
            }
        }

        if (accountIds.isEmpty()) {
            return;
        }

        Map<Id, Account> accountMap = new Map<Id, Account>([
            SELECT Id, OwnerId, Name FROM Account WHERE Id IN :accountIds
        ]);

        List<Task> tasks = new List<Task>();
        for (Case c : cases) {
            if (c.Priority != 'High' || c.AccountId == null) {
                continue;
            }
            Account acc = accountMap.get(c.AccountId);
            if (acc == null) {
                continue;
            }

            tasks.add(new Task(
                Subject       = 'URGENTE: Case de alta prioridade aberto - ' + c.CaseNumber,
                WhatId        = c.AccountId,
                OwnerId       = acc.OwnerId,
                Priority      = 'High',
                Status        = 'Not Started',
                ActivityDate  = Date.today().addDays(1),
                Description   = 'Case ID: ' + c.Id + ' | Conta: ' + acc.Name
            ));
        }

        if (!tasks.isEmpty()) {
            insert tasks;
        }
    }

    // Dispara recálculo do health score quando case é fechado
    private static void triggerHealthRecalculation(List<Case> closedCases) {
        Set<Id> accountIds = new Set<Id>();
        for (Case c : closedCases) {
            if (c.AccountId != null) {
                accountIds.add(c.AccountId);
            }
        }

        if (!accountIds.isEmpty()) {
            CustomerHealthService.calculateHealth(new List<Id>(accountIds));
        }
    }
}
