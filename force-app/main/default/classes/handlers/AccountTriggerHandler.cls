public class AccountTriggerHandler extends TriggerHandler {

    private List<Account> newList;
    private Map<Id, Account> oldMap;

    public AccountTriggerHandler() {
        this.newList = (List<Account>) Trigger.new;
        this.oldMap  = (Map<Id, Account>) Trigger.oldMap;
    }

    override protected void afterInsert() {
        List<Account> withCep = new List<Account>();
        for (Account acc : newList) {
            if (String.isNotBlank(acc.CEP__c)) {
                withCep.add(acc);
            }
        }
        if (!withCep.isEmpty()) {
            ViaCEPCalloutService.enrichAddress(withCep);
        }
    }

    override protected void afterUpdate() {
        List<Account> cepChanged = new List<Account>();
        for (Account acc : newList) {
            Account old = oldMap.get(acc.Id);
            if (acc.CEP__c != old.CEP__c && String.isNotBlank(acc.CEP__c)) {
                cepChanged.add(acc);
            }
        }
        if (!cepChanged.isEmpty()) {
            ViaCEPCalloutService.enrichAddress(cepChanged);
        }
    }
}
