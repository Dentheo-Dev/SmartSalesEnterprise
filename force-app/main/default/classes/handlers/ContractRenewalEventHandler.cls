public with sharing class ContractRenewalEventHandler {

    private static final Integer URGENT_DAYS_THRESHOLD = 7;

    public static void handleAfterInsert(List<Contract_Renewal_Alert__e> events) {
        List<Task> tasks = new List<Task>();

        for (Contract_Renewal_Alert__e evt : events) {
            Integer daysLeft = evt.Days_Until_Expiration__c != null
                ? Integer.valueOf(evt.Days_Until_Expiration__c) : 30;

            String valueFormatted = evt.Renewal_Value__c != null
                ? 'R$ ' + evt.Renewal_Value__c.setScale(2).format()
                : 'N/A';

            tasks.add(new Task(
                Subject      = 'Renovação Pendente: ' + evt.Account_Name__c
                               + ' (' + daysLeft + ' dias)',
                WhatId       = evt.Account_Id__c,
                Status       = 'Not Started',
                Priority     = daysLeft <= URGENT_DAYS_THRESHOLD ? 'High' : 'Normal',
                ActivityDate = Date.today().addDays(1),
                Description  = 'Renovação de contrato próxima do vencimento.'
                               + '\nCliente: '          + evt.Account_Name__c
                               + '\nDias restantes: '   + daysLeft
                               + '\nValor estimado: '   + valueFormatted
                               + '\nAção: Iniciar processo de renovação no Salesforce.'
            ));
        }

        if (!tasks.isEmpty()) {
            insert tasks;
        }
    }
}
