trigger OpportunityStageChangedTrigger on Opportunity_Stage_Changed__e (after insert) {
    OpportunityStageEventHandler.handleAfterInsert(Trigger.new);
}
