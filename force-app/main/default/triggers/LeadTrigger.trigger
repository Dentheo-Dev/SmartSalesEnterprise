trigger LeadTrigger on Lead (
    before insert,
    after insert, after update
) {
    new LeadTriggerHandler().run();
}
