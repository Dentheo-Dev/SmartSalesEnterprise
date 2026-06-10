public with sharing class SlackCalloutService {

    private static final String NAMED_CREDENTIAL = 'callout:SmartSales_Slack';

    // Wrapper chamado pelo trigger (contexto síncrono, sem callout)
    public static void notifyClosedWon(List<Opportunity> opps) {
        if (opps == null || opps.isEmpty()) return;
        Set<Id> ids = new Map<Id, Opportunity>(opps).keySet();
        notifyClosedWonAsync(ids);
    }

    @future(callout=true)
    private static void notifyClosedWonAsync(Set<Id> oppIds) {
        List<Opportunity> opps = [
            SELECT Id, Name, Amount, Owner.Name, Account.Name, CloseDate
            FROM Opportunity
            WHERE Id IN :oppIds
        ];

        List<Integration_Log__c> logs = new List<Integration_Log__c>();
        for (Opportunity opp : opps) {
            logs.add(sendClosedWonNotification(opp));
        }
        IntegrationLogService.save(logs);
    }

    private static Integration_Log__c sendClosedWonNotification(Opportunity opp) {
        Long startTime  = System.currentTimeMillis();
        String requestBody = JSON.serialize(buildPayload(opp));

        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(requestBody);
        req.setTimeout(10000);

        String  responseBody = '';
        Integer statusCode   = 0;
        String  errorMessage = null;
        Boolean success      = false;

        try {
            HttpResponse res = new Http().send(req);
            statusCode   = res.getStatusCode();
            responseBody = res.getBody();
            success      = statusCode >= 200 && statusCode < 300;
            if (!success) {
                errorMessage = 'HTTP ' + statusCode + ': ' + responseBody;
            }
        } catch (Exception e) {
            errorMessage = e.getMessage();
        }

        return IntegrationLogService.buildLog(
            'Slack_ClosedWon', requestBody, responseBody, statusCode,
            success, System.currentTimeMillis() - startTime,
            opp.Id, errorMessage
        );
    }

    private static Map<String, Object> buildPayload(Opportunity opp) {
        String amount = opp.Amount != null
            ? 'R$ ' + opp.Amount.setScale(2).format()
            : 'N/A';

        return new Map<String, Object>{
            'text' => '*Nova Venda Fechada!* :tada:',
            'attachments' => new List<Object>{
                new Map<String, Object>{
                    'color'  => '#36a64f',
                    'fields' => new List<Object>{
                        new Map<String, Object>{'title' => 'Oportunidade', 'value' => opp.Name,                    'short' => true},
                        new Map<String, Object>{'title' => 'Valor',        'value' => amount,                     'short' => true},
                        new Map<String, Object>{'title' => 'Conta',        'value' => opp.Account?.Name,          'short' => true},
                        new Map<String, Object>{'title' => 'Vendedor',     'value' => opp.Owner.Name,             'short' => true},
                        new Map<String, Object>{'title' => 'Fechamento',   'value' => String.valueOf(opp.CloseDate), 'short' => true}
                    }
                }
            }
        };
    }
}
