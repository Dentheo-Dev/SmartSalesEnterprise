public with sharing class CustomerHealthService {

    /**
     * Calcula e persiste Customer_Health__c para as accounts informadas.
     * Score base 70. Regras: +20 NPS>8, -20 NPS<5, -30 cases>5,
     * -25 sem compra há >365 dias, -20 atrasos de pagamento>2.
     */
    public static void calculateHealth(List<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return;
        }

        Set<Id> accountIdSet = new Set<Id>(accountIds);

        Map<Id, Customer_Health__c> healthByAccount =
            CustomerHealthSelector.getInstance().selectLatestByAccountIds(accountIdSet);

        Map<Id, Integer> openCasesByAccount = new Map<Id, Integer>();
        for (AggregateResult ar : CaseSelector.getInstance().selectOpenCasesCountByAccountIds(accountIdSet)) {
            openCasesByAccount.put(
                (Id) ar.get('AccountId'),
                Integer.valueOf(ar.get('total'))
            );
        }

        Map<Id, Date> lastPurchaseByAccount = new Map<Id, Date>();
        for (Opportunity opp : OpportunitySelector.getInstance().selectClosedWonByAccountIds(accountIdSet)) {
            if (!lastPurchaseByAccount.containsKey(opp.AccountId)) {
                lastPurchaseByAccount.put(opp.AccountId, opp.CloseDate);
            }
        }

        List<Customer_Health__c> toUpsert = new List<Customer_Health__c>();

        for (Id accId : accountIdSet) {
            Integer score        = 70;
            Integer openCases    = openCasesByAccount.containsKey(accId)
                ? openCasesByAccount.get(accId) : 0;
            Integer paymentDelays  = 0;
            Decimal npsScore       = null;
            Integer lastPurchaseDays = 365 * 10; // padrão: sem compra recente

            if (healthByAccount.containsKey(accId)) {
                Customer_Health__c existing = healthByAccount.get(accId);
                paymentDelays = existing.Payment_Delays__c != null
                    ? Integer.valueOf(existing.Payment_Delays__c) : 0;
                npsScore = existing.NPS_Score__c;
            }

            if (lastPurchaseByAccount.containsKey(accId)) {
                lastPurchaseDays = lastPurchaseByAccount.get(accId).daysBetween(Date.today());
            }

            // Aplicação das regras de pontuação
            if (openCases > 5)                         score -= 30;
            if (lastPurchaseDays > 365)                score -= 25;
            if (paymentDelays > 2)                     score -= 20;
            if (npsScore != null && npsScore > 8)      score += 20;
            if (npsScore != null && npsScore < 5)      score -= 20;

            score = Math.max(0, Math.min(100, score));

            Customer_Health__c ch = healthByAccount.containsKey(accId)
                ? healthByAccount.get(accId)
                : new Customer_Health__c(Account__c = accId, Name = 'Health Score');

            ch.Health_Score__c       = score;
            ch.Health_Status__c      = getHealthStatus(score);
            ch.Open_Cases__c         = openCases;
            ch.Last_Purchase_Days__c = lastPurchaseDays;
            ch.Last_Calculated__c    = Datetime.now();

            toUpsert.add(ch);
        }

        if (!toUpsert.isEmpty()) {
            upsert toUpsert;
            publishHealthAlerts(toUpsert, healthByAccount);
        }
    }

    private static void publishHealthAlerts(
        List<Customer_Health__c> upserted,
        Map<Id, Customer_Health__c> previousHealthByAccount
    ) {
        Set<String> alertStatuses = new Set<String>{ 'Crítico', 'Em Risco' };
        List<SObject> events = new List<SObject>();

        Set<Id> accountIds = new Set<Id>();
        for (Customer_Health__c ch : upserted) {
            accountIds.add(ch.Account__c);
        }
        Map<Id, Account> accountsById = new Map<Id, Account>(
            [SELECT Id, Name FROM Account WHERE Id IN :accountIds]
        );

        for (Customer_Health__c ch : upserted) {
            if (!alertStatuses.contains(ch.Health_Status__c)) continue;

            Customer_Health__c prev = previousHealthByAccount.get(ch.Account__c);
            String previousStatus  = prev != null ? prev.Health_Status__c : 'Saudável';

            Account acc = accountsById.get(ch.Account__c);
            String accountName = acc != null ? acc.Name : String.valueOf(ch.Account__c);

            events.add(new Customer_Health_Alert__e(
                Account_Id__c      = String.valueOf(ch.Account__c),
                Account_Name__c    = accountName,
                Health_Score__c    = ch.Health_Score__c,
                Health_Status__c   = ch.Health_Status__c,
                Previous_Status__c = previousStatus
            ));
        }

        PlatformEventService.publishAll(events);
    }

    private static String getHealthStatus(Integer score) {
        if (score <= 30)       return 'Crítico';
        else if (score <= 60)  return 'Em Risco';
        else if (score <= 80)  return 'Saudável';
        else                   return 'Excelente';
    }
}
