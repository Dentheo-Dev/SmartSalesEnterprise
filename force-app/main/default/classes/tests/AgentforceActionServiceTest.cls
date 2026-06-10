@IsTest
private class AgentforceActionServiceTest {

    private class OpenAIMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(JSON.serialize(new Map<String, Object>{
                'choices' => new List<Object>{
                    new Map<String, Object>{
                        'message' => new Map<String, Object>{
                            'role'    => 'assistant',
                            'content' => 'Insight Agentforce gerado.'
                        }
                    }
                }
            }));
            return res;
        }
    }

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Agentforce Corp');
        insert acc;
        insert new Opportunity(
            Name      = 'Deal Agentforce',
            AccountId = acc.Id,
            StageName = 'Closed Won',
            CloseDate = Date.today().addDays(30),
            Amount    = 100000
        );
    }

    @IsTest
    static void testGenerateInsight_opportunity_sucesso() {
        Test.setMock(HttpCalloutMock.class, new OpenAIMock());
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;

        AgentforceActionService.InsightRequest req = new AgentforceActionService.InsightRequest();
        req.recordId    = oppId;
        req.insightType = AIInsightService.TYPE_OPPORTUNITY;

        Test.startTest();
        List<AgentforceActionService.InsightResult> results =
            AgentforceActionService.generateInsight(
                new List<AgentforceActionService.InsightRequest>{ req }
            );
        Test.stopTest();

        Assert.areEqual(1, results.size());
        Assert.isTrue(results[0].success, 'Resultado deve indicar sucesso');
        Assert.isNull(results[0].errorMessage);
        Assert.isTrue(results[0].insightText.contains(oppId), 'insightText deve conter o ID do registro');
    }

    @IsTest
    static void testGenerateInsight_tipoInvalido_retornaErro() {
        Test.setMock(HttpCalloutMock.class, new OpenAIMock());
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;

        AgentforceActionService.InsightRequest req = new AgentforceActionService.InsightRequest();
        req.recordId    = oppId;
        req.insightType = 'TIPO_INVALIDO';

        Test.startTest();
        List<AgentforceActionService.InsightResult> results =
            AgentforceActionService.generateInsight(
                new List<AgentforceActionService.InsightRequest>{ req }
            );
        Test.stopTest();

        Assert.areEqual(1, results.size());
        Assert.isFalse(results[0].success, 'Deve retornar falha para tipo inválido');
        Assert.isTrue(results[0].errorMessage.contains('inválido'), 'Mensagem deve indicar tipo inválido');
    }

    @IsTest
    static void testGenerateInsight_listaVazia() {
        Test.startTest();
        List<AgentforceActionService.InsightResult> results =
            AgentforceActionService.generateInsight(
                new List<AgentforceActionService.InsightRequest>()
            );
        Test.stopTest();

        Assert.areEqual(0, results.size(), 'Lista vazia deve retornar zero resultados');
    }

    @IsTest
    static void testGenerateInsight_multiplosRequests() {
        Test.setMock(HttpCalloutMock.class, new OpenAIMock());
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;

        List<AgentforceActionService.InsightRequest> requests = new List<AgentforceActionService.InsightRequest>();
        for (Integer i = 0; i < 3; i++) {
            AgentforceActionService.InsightRequest req = new AgentforceActionService.InsightRequest();
            req.recordId    = oppId;
            req.insightType = AIInsightService.TYPE_OPPORTUNITY;
            requests.add(req);
        }

        Test.startTest();
        List<AgentforceActionService.InsightResult> results =
            AgentforceActionService.generateInsight(requests);
        Test.stopTest();

        Assert.areEqual(3, results.size(), 'Deve processar todos os requests');
        for (AgentforceActionService.InsightResult r : results) {
            Assert.isTrue(r.success);
        }
    }
}
