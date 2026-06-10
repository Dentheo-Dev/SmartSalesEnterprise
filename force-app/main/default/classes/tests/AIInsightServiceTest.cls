@IsTest
private class AIInsightServiceTest {

    private class OpenAIMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(JSON.serialize(new Map<String, Object>{
                'choices' => new List<Object>{
                    new Map<String, Object>{
                        'message' => new Map<String, Object>{
                            'role'    => 'assistant',
                            'content' => 'Recomendação gerada pela IA.'
                        }
                    }
                }
            }));
            return res;
        }
    }

    private class OpenAINullMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(JSON.serialize(new Map<String, Object>{
                'choices' => new List<Object>()
            }));
            return res;
        }
    }

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Tech Corp Enterprise', Industry = 'Technology');
        insert acc;

        Opportunity opp = new Opportunity(
            Name      = 'Licença Enterprise Anual',
            AccountId = acc.Id,
            StageName = 'Closed Won',
            CloseDate = Date.today().addDays(30),
            Amount    = 200000
        );
        insert opp;

        insert new Product_Proposal__c(
            Name                   = 'PROP-AI-001',
            Opportunity__c         = opp.Id,
            Account__c             = acc.Id,
            Total_Value__c         = 200000,
            Discount_Percentage__c = 5,
            Status__c              = 'Rascunho',
            Valid_Until__c         = Date.today().addDays(30)
        );

        insert new Customer_Health__c(
            Name                  = 'Health Score',
            Account__c            = acc.Id,
            Health_Score__c       = 68,
            Health_Status__c      = 'Saudável',
            Open_Cases__c         = 2,
            NPS_Score__c          = 7,
            Payment_Delays__c     = 1,
            Last_Purchase_Days__c = 90
        );
    }

    @IsTest
    static void testEnrichOpportunityNextStep() {
        Test.setMock(HttpCalloutMock.class, new OpenAIMock());
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;

        Test.startTest();
        AIInsightService.enrichOpportunityNextStep(oppId);
        Test.stopTest();

        String result = [SELECT AI_Next_Step__c FROM Opportunity WHERE Id = :oppId].AI_Next_Step__c;
        Assert.areEqual('Recomendação gerada pela IA.', result, 'AI_Next_Step__c deve ser preenchido');
    }

    @IsTest
    static void testEnrichProposalSummary() {
        Test.setMock(HttpCalloutMock.class, new OpenAIMock());
        Id propId = [SELECT Id FROM Product_Proposal__c LIMIT 1].Id;

        Test.startTest();
        AIInsightService.enrichProposalSummary(propId);
        Test.stopTest();

        String result = [SELECT AI_Summary__c FROM Product_Proposal__c WHERE Id = :propId].AI_Summary__c;
        Assert.areEqual('Recomendação gerada pela IA.', result, 'AI_Summary__c deve ser preenchido');
    }

    @IsTest
    static void testEnrichHealthAnalysis() {
        Test.setMock(HttpCalloutMock.class, new OpenAIMock());
        Id healthId = [SELECT Id FROM Customer_Health__c LIMIT 1].Id;

        Test.startTest();
        AIInsightService.enrichHealthAnalysis(healthId);
        Test.stopTest();

        String result = [SELECT AI_Health_Analysis__c FROM Customer_Health__c WHERE Id = :healthId].AI_Health_Analysis__c;
        Assert.areEqual('Recomendação gerada pela IA.', result, 'AI_Health_Analysis__c deve ser preenchido');
    }

    @IsTest
    static void testEnrichOpportunityNextStep_insightNulo_naoAtualiza() {
        Test.setMock(HttpCalloutMock.class, new OpenAINullMock());
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;

        Test.startTest();
        AIInsightService.enrichOpportunityNextStep(oppId);
        Test.stopTest();

        // Campo deve permanecer nulo sem lançar exceção
        String result = [SELECT AI_Next_Step__c FROM Opportunity WHERE Id = :oppId].AI_Next_Step__c;
        Assert.isNull(result, 'Campo não deve ser atualizado quando insight é nulo');
    }

    @IsTest
    static void testEnrichProposalSummary_insightNulo_naoAtualiza() {
        Test.setMock(HttpCalloutMock.class, new OpenAINullMock());
        Id propId = [SELECT Id FROM Product_Proposal__c LIMIT 1].Id;

        Test.startTest();
        AIInsightService.enrichProposalSummary(propId);
        Test.stopTest();

        String result = [SELECT AI_Summary__c FROM Product_Proposal__c WHERE Id = :propId].AI_Summary__c;
        Assert.isNull(result, 'Campo não deve ser atualizado quando insight é nulo');
    }
}
