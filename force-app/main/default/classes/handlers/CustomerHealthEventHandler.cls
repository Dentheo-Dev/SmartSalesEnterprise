public with sharing class CustomerHealthEventHandler {

    private static final Set<String> ALERT_STATUSES = new Set<String>{ 'Crítico', 'Em Risco' };

    public static void handleAfterInsert(List<Customer_Health_Alert__e> events) {
        List<Task> tasks = new List<Task>();

        for (Customer_Health_Alert__e evt : events) {
            if (!ALERT_STATUSES.contains(evt.Health_Status__c)) {
                continue;
            }

            tasks.add(new Task(
                Subject      = 'Alerta de Saúde: ' + evt.Account_Name__c
                               + ' (' + evt.Health_Status__c + ')',
                WhatId       = evt.Account_Id__c,
                Status       = 'Not Started',
                Priority     = evt.Health_Status__c == 'Crítico' ? 'High' : 'Normal',
                ActivityDate = Date.today().addDays(1),
                Description  = 'Health Score: ' + Integer.valueOf(evt.Health_Score__c)
                               + '\nStatus anterior: ' + evt.Previous_Status__c
                               + '\nStatus atual: ' + evt.Health_Status__c
                               + '\nAção recomendada: Contatar cliente para retenção proativa.'
            ));
        }

        if (!tasks.isEmpty()) {
            insert tasks;
        }
    }
}
