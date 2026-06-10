trigger ContractRenewalAlertTrigger on Contract_Renewal_Alert__e (after insert) {
    ContractRenewalEventHandler.handleAfterInsert(Trigger.new);
}
