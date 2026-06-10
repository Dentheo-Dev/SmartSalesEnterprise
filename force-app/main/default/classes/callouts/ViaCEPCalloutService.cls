public with sharing class ViaCEPCalloutService {

    private static final String NAMED_CREDENTIAL = 'callout:SmartSales_ViaCEP';

    // Wrapper chamado pelo trigger — extrai IDs e despacha assincronamente
    public static void enrichAddress(List<Account> accounts) {
        if (accounts == null || accounts.isEmpty()) return;
        Set<Id> ids = new Map<Id, Account>(accounts).keySet();
        enrichAddressAsync(ids);
    }

    @future(callout=true)
    private static void enrichAddressAsync(Set<Id> accountIds) {
        List<Account> accounts = [
            SELECT Id, CEP__c, BillingStreet, Bairro__c,
                   BillingCity, BillingState, BillingPostalCode, BillingCountry
            FROM Account
            WHERE Id IN :accountIds
              AND CEP__c != null
        ];

        List<Account>            toUpdate = new List<Account>();
        List<Integration_Log__c> logs     = new List<Integration_Log__c>();

        for (Account acc : accounts) {
            String cep = acc.CEP__c.replaceAll('[^0-9]', '');
            if (cep.length() != 8) continue;

            Integration_Log__c log = callViaCEP(acc, cep);
            logs.add(log);

            if (log.Success__c) {
                toUpdate.add(acc);
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
        IntegrationLogService.save(logs);
    }

    private static Integration_Log__c callViaCEP(Account acc, String cep) {
        Long    startTime   = System.currentTimeMillis();
        String  endpoint    = NAMED_CREDENTIAL + '/ws/' + cep + '/json/';
        String  responseBody = '';
        Integer statusCode   = 0;
        String  errorMessage = null;
        Boolean success      = false;

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setTimeout(10000);

        try {
            HttpResponse res = new Http().send(req);
            statusCode   = res.getStatusCode();
            responseBody = res.getBody();

            if (statusCode == 200) {
                Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                if (data.get('erro') == null) {
                    acc.BillingStreet     = (String) data.get('logradouro');
                    acc.Bairro__c         = (String) data.get('bairro');
                    acc.BillingCity       = (String) data.get('localidade');
                    acc.BillingPostalCode = cep;
                    // BillingState/BillingCountry omitidos: org usa picklists, formato varia por configuração
                    success = true;
                } else {
                    errorMessage = 'CEP não encontrado: ' + cep;
                }
            } else {
                errorMessage = 'HTTP ' + statusCode;
            }
        } catch (Exception e) {
            errorMessage = e.getMessage();
        }

        return IntegrationLogService.buildLog(
            'ViaCEP', endpoint, responseBody, statusCode,
            success, System.currentTimeMillis() - startTime,
            acc.Id, errorMessage
        );
    }
}
