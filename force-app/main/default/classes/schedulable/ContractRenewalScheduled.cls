public with sharing class ContractRenewalScheduled implements Schedulable {

    private static final Integer DIAS_ALERTA = 30;

    public void execute(SchedulableContext sc) {
        Date alertThreshold = Date.today().addDays(DIAS_ALERTA);

        List<Contract_Renewal__c> expiringSoon = [
            SELECT Id, Name, Account__r.Name, Original_Contract_End__c,
                   Renewal_Value__c, Owner__r.Email, Owner__r.Name
            FROM Contract_Renewal__c
            WHERE Original_Contract_End__c <= :alertThreshold
              AND Original_Contract_End__c >= TODAY
              AND Status__c NOT IN ('Renovado', 'Cancelado')
        ];

        if (!expiringSoon.isEmpty()) {
            sendAlerts(expiringSoon);
            publishRenewalEvents(expiringSoon);
        }
    }

    private static void publishRenewalEvents(List<Contract_Renewal__c> renewals) {
        List<SObject> events = new List<SObject>();

        for (Contract_Renewal__c cr : renewals) {
            Integer daysLeft   = Date.today().daysBetween(cr.Original_Contract_End__c);
            String accountName = cr.Account__r != null ? cr.Account__r.Name : cr.Name;

            events.add(new Contract_Renewal_Alert__e(
                Contract_Renewal_Id__c   = String.valueOf(cr.Id),
                Account_Id__c            = String.valueOf(cr.Account__c),
                Account_Name__c          = accountName,
                Days_Until_Expiration__c = daysLeft,
                Renewal_Value__c         = cr.Renewal_Value__c
            ));
        }

        PlatformEventService.publishAll(events);
    }

    private void sendAlerts(List<Contract_Renewal__c> renewals) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Contract_Renewal__c cr : renewals) {
            String ownerEmail = cr.Owner__r?.Email;
            if (String.isBlank(ownerEmail)) {
                continue;
            }

            Integer daysLeft   = Date.today().daysBetween(cr.Original_Contract_End__c);
            String accountName = cr.Account__r != null ? cr.Account__r.Name : cr.Name;

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{ ownerEmail });
            email.setSubject('Renovação Pendente — ' + accountName + ' (' + daysLeft + ' dias)');
            email.setPlainTextBody(
                'Alerta de renovação de contrato:\n\n'
                + 'Cliente: '         + accountName + '\n'
                + 'Vencimento: '      + cr.Original_Contract_End__c + '\n'
                + 'Dias restantes: '  + daysLeft + '\n'
                + 'Valor: R$ '        + (cr.Renewal_Value__c != null ? cr.Renewal_Value__c.format() : 'N/A')
                + '\n\nAcesse o Salesforce para iniciar o processo de renovação.'
            );
            emails.add(email);
        }

        if (!emails.isEmpty()) {
            try {
                Messaging.sendEmail(emails);
            } catch (Exception e) {
                System.debug(LoggingLevel.WARN,
                    'ContractRenewalScheduled: falha ao enviar alertas — ' + e.getMessage());
            }
        }
    }
}
