@IsTest
private class OpenAICalloutServiceTest {

    private class SuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(JSON.serialize(new Map<String, Object>{
                'choices' => new List<Object>{
                    new Map<String, Object>{
                        'message' => new Map<String, Object>{
                            'role'    => 'assistant',
                            'content' => 'Insight gerado com sucesso.'
                        }
                    }
                }
            }));
            return res;
        }
    }

    private class ErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(401);
            res.setBody('{"error": {"message": "Unauthorized - Invalid API Key"}}');
            return res;
        }
    }

    private class MalformedMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('not-valid-json{{');
            return res;
        }
    }

    private class EmptyChoicesMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(JSON.serialize(new Map<String, Object>{
                'choices' => new List<Object>()
            }));
            return res;
        }
    }

    @IsTest
    static void testSuccess() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        String result = OpenAICalloutService.generateChatCompletion('Você é assistente.', 'Gere um insight.');
        Test.stopTest();

        Assert.areEqual('Insight gerado com sucesso.', result, 'Deve retornar o conteúdo da resposta');
        List<Integration_Log__c> logs = [SELECT Success__c, Status_Code__c FROM Integration_Log__c];
        Assert.areEqual(1, logs.size(), 'Deve criar log de integração');
        Assert.isTrue(logs[0].Success__c, 'Log deve indicar sucesso');
        Assert.areEqual(200, Integer.valueOf(logs[0].Status_Code__c));
    }

    @IsTest
    static void testHttpError() {
        Test.setMock(HttpCalloutMock.class, new ErrorMock());

        Test.startTest();
        String result = OpenAICalloutService.generateChatCompletion('System', 'User');
        Test.stopTest();

        Assert.isNull(result, 'Deve retornar null em erro HTTP');
        List<Integration_Log__c> logs = [SELECT Success__c, Error_Message__c, Status_Code__c FROM Integration_Log__c];
        Assert.areEqual(1, logs.size());
        Assert.isFalse(logs[0].Success__c, 'Log deve indicar falha');
        Assert.areEqual(401, Integer.valueOf(logs[0].Status_Code__c));
        Assert.isTrue(logs[0].Error_Message__c.contains('401'));
    }

    @IsTest
    static void testMalformedResponse() {
        Test.setMock(HttpCalloutMock.class, new MalformedMock());

        Test.startTest();
        String result = OpenAICalloutService.generateChatCompletion('System', 'User');
        Test.stopTest();

        Assert.isNull(result, 'Deve retornar null para JSON inválido');
        Assert.areEqual(1, [SELECT COUNT() FROM Integration_Log__c]);
    }

    @IsTest
    static void testEmptyChoices() {
        Test.setMock(HttpCalloutMock.class, new EmptyChoicesMock());

        Test.startTest();
        String result = OpenAICalloutService.generateChatCompletion('System', 'User');
        Test.stopTest();

        Assert.isNull(result, 'Deve retornar null para choices vazio');
    }

    @IsTest
    static void testLogsRequestAndResponse() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        OpenAICalloutService.generateChatCompletion('System prompt', 'User prompt');
        Test.stopTest();

        Integration_Log__c log = [
            SELECT Service_Name__c, Request_Body__c, Response_Body__c
            FROM Integration_Log__c
            LIMIT 1
        ];
        Assert.areEqual('OpenAI_Chat', log.Service_Name__c);
        Assert.isTrue(log.Request_Body__c.contains('gpt-4o-mini'), 'Request deve conter o modelo');
        Assert.isTrue(log.Response_Body__c.contains('choices'), 'Response deve ser logada');
    }
}
