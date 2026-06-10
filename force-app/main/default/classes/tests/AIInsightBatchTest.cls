@IsTest
private class AIInsightBatchTest {

    private class OpenAIMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(JSON.serialize(new Map<String, Object>{
                'choices' => new List<Object>{
                    new Map<String, Object>{
                        'message' => new Map<String, Object>{
                            'role'    => 'assistant',
                            'content' => 'Análise de health gerada pelo batch.'
                        }
                    }
                }
            }));
            return res;
        }
    }

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'AI Batch Corp');
        insert acc;

        insert new List<Customer_Health__c>{
            new Customer_Health__c(
                Name = 'Health Sem Analise', Account__c = acc.Id,
                Health_Score__c = 55, Health_Status__c = 'Em Risco',
                AI_Health_Analysis__c = null
            ),
            new Customer_Health__c(
                Name = 'Health Com Analise', Account__c = acc.Id,
                Health_Score__c = 80, Health_Status__c = 'Saudável',
                AI_Health_Analysis__c = 'Análise preexistente — não deve ser reprocessada.'
            )
        };
    }

    @IsTest
    static void testBatchGeraInsights() {
        Test.setMock(HttpCalloutMock.class, new OpenAIMock());

        Test.startTest();
        Database.executeBatch(new AIInsightBatch(), 10);
        Test.stopTest();

        // Health sem análise deve ter sido enriquecido
        Customer_Health__c processed = [
            SELECT AI_Health_Analysis__c
            FROM Customer_Health__c
            WHERE Name = 'Health Sem Analise'
        ];
        System.assertEquals(
            'Análise de health gerada pelo batch.',
            processed.AI_Health_Analysis__c,
            'Health sem análise deve ter sido enriquecido'
        );
    }

    @IsTest
    static void testBatchNaoReprocessaAnalisesExistentes() {
        Test.setMock(HttpCalloutMock.class, new OpenAIMock());

        Test.startTest();
        Database.executeBatch(new AIInsightBatch(), 10);
        Test.stopTest();

        Customer_Health__c untouched = [
            SELECT AI_Health_Analysis__c
            FROM Customer_Health__c
            WHERE Name = 'Health Com Analise'
        ];
        System.assertEquals(
            'Análise preexistente — não deve ser reprocessada.',
            untouched.AI_Health_Analysis__c,
            'Health com análise existente não deve ser sobrescrito'
        );
    }

    @IsTest
    static void testBatchSemRegistros() {
        List<Customer_Health__c> healths = [SELECT Id, AI_Health_Analysis__c FROM Customer_Health__c];
        for (Customer_Health__c h : healths) {
            h.AI_Health_Analysis__c = 'Análise preexistente';
        }
        update healths;

        Test.setMock(HttpCalloutMock.class, new OpenAIMock());
        Test.startTest();
        Database.executeBatch(new AIInsightBatch(), 10);
        Test.stopTest();

        System.assert(true, 'Batch sem registros elegíveis deve completar sem erro');
    }

    @IsTest
    static void testSchedulable() {
        Test.startTest();
        String jobId = System.schedule('TestAIInsightBatch', '0 0 7 ? * MON', new AIInsightBatch());
        Test.stopTest();

        CronTrigger ct = [SELECT Id, CronExpression FROM CronTrigger WHERE Id = :jobId];
        System.assertNotEquals(null, ct.Id);
        System.assertEquals('0 0 7 ? * MON', ct.CronExpression);
    }
}
