public with sharing class LeadScoredEventHandler {

    private static final Integer HIGH_SCORE_THRESHOLD = 70;

    public static void handleAfterInsert(List<Lead_Scored__e> events) {
        List<Task> tasks = new List<Task>();

        for (Lead_Scored__e evt : events) {
            if (evt.Score__c == null || evt.Score__c < HIGH_SCORE_THRESHOLD) {
                continue;
            }

            tasks.add(new Task(
                Subject      = 'Lead Qualificado — Score ' + Integer.valueOf(evt.Score__c),
                WhoId        = evt.Lead_Id__c,
                Status       = 'Not Started',
                Priority     = 'High',
                ActivityDate = Date.today().addDays(1),
                Description  = 'Lead atingiu score ' + Integer.valueOf(evt.Score__c)
                               + '. Motivos: ' + evt.Score_Reason__c
            ));
        }

        if (!tasks.isEmpty()) {
            insert tasks;
        }
    }
}
