@IsTest
private class OpportunityTriggerHandlerTest {

    // Mock unificado: responde tanto para Slack quanto para OpenAI com base no endpoint
    private class MultiCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            String endpoint  = req.getEndpoint();

            if (endpoint.contains('SmartSales_Slack')) {
                res.setStatusCode(200);
                res.setBody('ok');
            } else {
                // OpenAI
                res.setStatusCode(200);
                res.setBody(JSON.serialize(new Map<String, Object>{
                    'choices' => new List<Object>{
                        new Map<String, Object>{
                            'message' => new Map<String, Object>{
                                'role'    => 'assistant',
                                'content' => 'Próximos passos sugeridos pela IA.'
                            }
                        }
                    }
                }));
            }
            return res;
        }
    }

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Trigger Handler Corp');
        insert acc;
        insert new Opportunity(
            Name      = 'Opp Trigger Test',
            AccountId = acc.Id,
            StageName = 'Proposal/Price Quote',
            CloseDate = Date.today().addDays(30),
            Amount    = 80000
        );
    }

    @IsTest
    static void testAfterUpdate_closedWon_geraAIInsight() {
        Test.setMock(HttpCalloutMock.class, new MultiCalloutMock());
        Opportunity opp = [SELECT Id, StageName FROM Opportunity LIMIT 1];

        Test.startTest();
        opp.StageName = 'Closed Won';
        update opp;
        Test.stopTest();

        Opportunity updated = [SELECT AI_Next_Step__c FROM Opportunity WHERE Id = :opp.Id];
        Assert.isTrue(
            String.isNotBlank(updated.AI_Next_Step__c),
            'AI_Next_Step__c deve ser preenchido ao fechar negócio'
        );
        Assert.areEqual('Próximos passos sugeridos pela IA.', updated.AI_Next_Step__c);
    }

    @IsTest
    static void testAfterUpdate_closedWon_notificaSlack() {
        Test.setMock(HttpCalloutMock.class, new MultiCalloutMock());
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        opp.StageName = 'Closed Won';
        update opp;
        Test.stopTest();

        List<Integration_Log__c> slackLogs = [
            SELECT Success__c FROM Integration_Log__c WHERE Service_Name__c = 'Slack_ClosedWon'
        ];
        Assert.areEqual(1, slackLogs.size(), 'Deve notificar Slack ao fechar negócio');
        Assert.isTrue(slackLogs[0].Success__c);
    }

    @IsTest
    static void testBeforeUpdate_dataFechamentoPassado_retornaErro() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        try {
            opp.CloseDate = Date.today().addDays(-5);
            update opp;
            Assert.fail('Deveria bloquear data de fechamento no passado');
        } catch (DmlException e) {
            Assert.isTrue(
                e.getMessage().contains('passado') || e.getMessage().contains('fechamento'),
                'Mensagem de erro deve mencionar a restrição de data'
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void testAfterInsert_calculaComissao() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        Opportunity newOpp = new Opportunity(
            Name      = 'Nova Opp Comissão',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(45),
            Amount    = 120000
        );
        insert newOpp;
        Test.stopTest();

        Assert.areEqual(1, [SELECT COUNT() FROM Opportunity WHERE Id = :newOpp.Id],
            'Opportunity deve ser inserida com sucesso'
        );
    }

    @IsTest
    static void testAfterUpdate_mudancaValor_recalculaComissao() {
        Opportunity opp = [SELECT Id, Amount FROM Opportunity LIMIT 1];

        Test.startTest();
        opp.Amount = 95000;
        update opp;
        Test.stopTest();

        Assert.areEqual(95000, [SELECT Amount FROM Opportunity WHERE Id = :opp.Id].Amount);
    }

    @IsTest
    static void testAfterUpdate_semMudancaStage_naoDisparaIA() {
        Opportunity opp = [SELECT Id, Amount FROM Opportunity LIMIT 1];

        Test.startTest();
        opp.Amount = 85000;
        update opp;
        Test.stopTest();

        // Sem mudança para Closed Won: nenhum log de OpenAI
        Assert.areEqual(
            0,
            [SELECT COUNT() FROM Integration_Log__c WHERE Service_Name__c = 'OpenAI_Chat'],
            'Não deve chamar OpenAI sem mudança de stage para Closed Won'
        );
    }
}
