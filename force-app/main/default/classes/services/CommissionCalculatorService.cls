public with sharing class CommissionCalculatorService {

    /**
     * Calcula e cria/atualiza Commission__c para cada Opportunity.
     * Faixas: ≤R$10k→3%, R$10k-R$50k→5%, R$50k-R$200k→7%, >R$200k→10%.
     */
    public static void calculateCommission(List<Opportunity> opps) {
        if (opps == null || opps.isEmpty()) {
            return;
        }

        Set<Id> oppIds = new Map<Id, Opportunity>(opps).keySet();

        Map<Id, Commission__c> existingByOpp = CommissionSelector.getInstance().selectByOpportunityIds(oppIds);

        List<Commission__c> toUpsert   = new List<Commission__c>();
        List<Opportunity>   oppsToFlag = new List<Opportunity>();
        String period = String.valueOf(Date.today().year()) + '-'
                      + String.valueOf(Date.today().month()).leftPad(2, '0');

        for (Opportunity opp : opps) {
            if (opp.Amount == null || opp.Amount <= 0) {
                continue;
            }

            Decimal rate             = getCommissionRate(opp.Amount);
            Decimal commissionAmount = opp.Amount * rate / 100;

            Commission__c commission = existingByOpp.containsKey(opp.Id)
                ? existingByOpp.get(opp.Id)
                : new Commission__c(Opportunity__c = opp.Id, Name = 'Comissão');

            commission.Commission_Rate__c   = rate;
            commission.Commission_Amount__c = commissionAmount;
            commission.Sales_Rep__c         = opp.OwnerId;
            commission.Status__c            = 'Calculada';
            commission.Period__c            = period;

            toUpsert.add(commission);
            oppsToFlag.add(new Opportunity(Id = opp.Id, Commission_Calculated__c = true));
        }

        if (!toUpsert.isEmpty()) {
            upsert toUpsert;
        }
        if (!oppsToFlag.isEmpty()) {
            update oppsToFlag;
        }
    }

    private static Decimal getCommissionRate(Decimal amount) {
        if (amount <= 10000)       return 3;
        else if (amount <= 50000)  return 5;
        else if (amount <= 200000) return 7;
        else                       return 10;
    }
}
