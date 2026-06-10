public with sharing class OpenAICalloutService {

    private static final String ENDPOINT    = 'callout:SmartSales_OpenAI/chat/completions';
    private static final String MODEL       = 'gpt-4o-mini';
    private static final Integer MAX_TOKENS = 500;

    public static String generateChatCompletion(String systemPrompt, String userPrompt) {
        Long   startTime   = System.currentTimeMillis();
        String requestBody = buildRequestBody(systemPrompt, userPrompt);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(ENDPOINT);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + getApiKey());
        req.setBody(requestBody);
        req.setTimeout(30000);

        String  responseBody = '';
        Integer statusCode   = 0;
        String  errorMessage = null;
        Boolean success      = false;
        String  content      = null;

        try {
            HttpResponse res = new Http().send(req);
            statusCode   = res.getStatusCode();
            responseBody = res.getBody();
            success      = statusCode == 200;

            if (success) {
                content = parseContent(responseBody);
            } else {
                errorMessage = 'HTTP ' + statusCode + ': ' + responseBody;
            }
        } catch (Exception e) {
            errorMessage = e.getMessage();
        }

        IntegrationLogService.save(new List<Integration_Log__c>{
            IntegrationLogService.buildLog(
                'OpenAI_Chat', requestBody, responseBody, statusCode,
                success, System.currentTimeMillis() - startTime,
                null, errorMessage
            )
        });

        return content;
    }

    private static String buildRequestBody(String systemPrompt, String userPrompt) {
        return JSON.serialize(new Map<String, Object>{
            'model'      => MODEL,
            'max_tokens' => MAX_TOKENS,
            'messages'   => new List<Object>{
                new Map<String, Object>{ 'role' => 'system', 'content' => systemPrompt },
                new Map<String, Object>{ 'role' => 'user',   'content' => userPrompt   }
            }
        });
    }

    private static String parseContent(String responseBody) {
        try {
            Map<String, Object> root    = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            List<Object>        choices = (List<Object>) root.get('choices');
            if (choices == null || choices.isEmpty()) return null;

            Map<String, Object> choice  = (Map<String, Object>) choices[0];
            Map<String, Object> message = (Map<String, Object>) choice.get('message');
            return (String) message.get('content');
        } catch (Exception e) {
            return null;
        }
    }

    // Lê a API key do Custom Setting AI_Settings__c (configurar via Setup > Custom Settings)
    @TestVisible
    private static String getApiKey() {
        AI_Settings__c settings = AI_Settings__c.getInstance();
        String key = settings?.OpenAI_API_Key__c;
        return String.isNotBlank(key) ? key : 'CONFIGURE_OPENAI_KEY_IN_SETUP';
    }
}
