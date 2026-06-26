public class OpportunityTriggerHandler extends TriggerHandler {

    private List<Opportunity> newList;
    private List<Opportunity> oldList;
    private Map<Id, Opportunity> newMap;
    private Map<Id, Opportunity> oldMap;

    private static final Map<String, Integer> STAGE_DEFAULT_DAYS = new Map<String, Integer>{
        'Prospecting'          => 30,
        'Qualification'        => 30,
        'Value Proposition'    => 15,
        'Id. Decision Makers'  => 15,
        'Perception Analysis'  => 15,
        'Proposal/Price Quote' => 15,
        'Negotiation/Review'   => 7
    };

    public OpportunityTriggerHandler() {
        this.newList = (List<Opportunity>) Trigger.new;
        this.oldList = (List<Opportunity>) Trigger.old;
        this.newMap  = (Map<Id, Opportunity>) Trigger.newMap;
        this.oldMap  = (Map<Id, Opportunity>) Trigger.oldMap;
    }

    override protected void beforeInsert() {
        setDefaultCloseDates(newList);
        validateCloseDates(newList);
    }

    override protected void beforeUpdate() {
        setDefaultCloseDates(newList);
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

    // Auto-define CloseDate baseado no Stage quando o usuário deixa como hoje ou null
    private static void setDefaultCloseDates(List<Opportunity> opps) {
        Date today = Date.today();
        for (Opportunity opp : opps) {
            Integer days = STAGE_DEFAULT_DAYS.get(opp.StageName);
            if (days != null && (opp.CloseDate == null || opp.CloseDate == today)) {
                opp.CloseDate = today.addDays(days);
            }
        }
    }

    // Close Date não pode ser no passado (exceto para oportunidades já encerradas)
    private static void validateCloseDates(List<Opportunity> opps) {
        Date today = Date.today();
        Set<String> closedStages = new Set<String>{ 'Closed Won', 'Closed Lost' };
        for (Opportunity opp : opps) {
            if (!closedStages.contains(opp.StageName)
                    && opp.CloseDate != null && opp.CloseDate < today) {
                opp.CloseDate.addError('A data de fechamento não pode ser no passado.');
            }
        }
    }
}
