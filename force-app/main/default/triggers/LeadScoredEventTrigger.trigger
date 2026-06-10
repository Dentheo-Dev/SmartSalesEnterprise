trigger LeadScoredEventTrigger on Lead_Scored__e (after insert) {
    LeadScoredEventHandler.handleAfterInsert(Trigger.new);
}
