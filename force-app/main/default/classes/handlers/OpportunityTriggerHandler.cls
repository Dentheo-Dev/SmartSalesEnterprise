public class OpportunityTriggerHandler extends TriggerHandler {

    private List<Opportunity> newList;
    private List<Opportunity> oldList;
    private Map<Id, Opportunity> newMap;
    private Map<Id, Opportunity> oldMap;

    public OpportunityTriggerHandler() {
        this.newList = (List<Opportunity>) Trigger.new;
        this.oldList = (List<Opportunity>) Trigger.old;
        this.newMap  = (Map<Id, Opportunity>) Trigger.newMap;
        this.oldMap  = (Map<Id, Opportunity>) Trigger.oldMap;
    }

    override protected void beforeInsert() {
        validateCloseDates(newList);
    }

    override protected void beforeUpdate() {
        validateCloseDates(newList);
    }

    override protected void afterInsert() {
        CommissionCalculatorService.calculateCommission(newList);
    }

    override protected void afterUpdate() {
        List<Opportunity> closedWon     = new List<Opportunity>();
        List<Opportunity> amountChanged = new List<Opportunity>();
        List<SObject>     stageEvents   = new List<SObject>();

        for (Opportunity opp : newList) {
            Opportunity old = oldMap.get(opp.Id);

            if (opp.StageName != old.StageName) {
                if (opp.StageName == 'Closed Won') {
                    closedWon.add(opp);
                }
                stageEvents.add(new Opportunity_Stage_Changed__e(
                    Opportunity_Id__c = String.valueOf(opp.Id),
                    Previous_Stage__c = old.StageName,
                    New_Stage__c      = opp.StageName,
                    Amount__c         = opp.Amount
                ));
            }
            if (opp.Amount != old.Amount) {
                amountChanged.add(opp);
            }
        }

        if (!closedWon.isEmpty()) {
            SlackCalloutService.notifyClosedWon(closedWon);
            for (Opportunity opp : closedWon) {
                AIInsightQueueable.enqueue(opp.Id, AIInsightService.TYPE_OPPORTUNITY);
            }
        }
        if (!amountChanged.isEmpty()) {
            CommissionCalculatorService.calculateCommission(amountChanged);
        }
        if (!stageEvents.isEmpty()) {
            PlatformEventService.publishAll(stageEvents);
        }
    }

    // Close Date não pode ser no passado
    private static void validateCloseDates(List<Opportunity> opps) {
        Date today = Date.today();
        for (Opportunity opp : opps) {
            if (opp.CloseDate != null && opp.CloseDate < today) {
                opp.CloseDate.addError('A data de fechamento não pode ser no passado.');
            }
        }
    }
}
