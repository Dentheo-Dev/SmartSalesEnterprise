public with sharing class OpportunityStageEventHandler {

    private static final Set<String> STAGES_REQUIRING_FOLLOWUP = new Set<String>{
        'Proposal/Price Quote', 'Negotiation/Review', 'Closed Lost'
    };

    public static void handleAfterInsert(List<Opportunity_Stage_Changed__e> events) {
        List<Task> tasks = new List<Task>();

        for (Opportunity_Stage_Changed__e evt : events) {
            if (evt.New_Stage__c == null
                    || !STAGES_REQUIRING_FOLLOWUP.contains(evt.New_Stage__c)) {
                continue;
            }

            tasks.add(new Task(
                Subject      = 'Follow-up: ' + evt.New_Stage__c,
                WhatId       = evt.Opportunity_Id__c,
                Status       = 'Not Started',
                Priority     = evt.New_Stage__c == 'Closed Lost' ? 'High' : 'Normal',
                ActivityDate = Date.today().addDays(2),
                Description  = 'Stage mudou de [' + evt.Previous_Stage__c
                               + '] para [' + evt.New_Stage__c + ']'
            ));
        }

        if (!tasks.isEmpty()) {
            insert tasks;
        }
    }
}
