trigger CustomerHealthAlertTrigger on Customer_Health_Alert__e (after insert) {
    CustomerHealthEventHandler.handleAfterInsert(Trigger.new);
}
