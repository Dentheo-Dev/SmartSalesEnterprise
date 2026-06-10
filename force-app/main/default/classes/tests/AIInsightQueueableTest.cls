@IsTest
private class AIInsightQueueableTest {

    private class OpenAIMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(JSON.serialize(new Map<String, Object>{
                'choices' => new List<Object>{
                    new Map<String, Object>{
                        'message' => new Map<String, Object>{
                            'role'    => 'assistant',
                            'content' => 'Insight via Queueable.'
                        }
                    }
                }
            }));
            return res;
        }
    }

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Queueable Corp');
        insert acc;

        Opportunity opp = new Opportunity(
            Name      = 'Deal Queueable',
            AccountId = acc.Id,
            StageName = 'Closed Won',
            CloseDate = Date.today().addDays(30),
            Amount    = 75000
        );
        insert opp;

        insert new Product_Proposal__c(
            Name                   = 'PROP-Q-001',
            Opportunity__c         = opp.Id,
            Account__c             = acc.Id,
            Total_Value__c         = 75000,
            Discount_Percentage__c = 0,
            Status__c              = 'Rascunho',
            Valid_Until__c         = Date.today().addDays(30)
        );

        insert new Customer_Health__c(
            Name                  = 'Health Score',
            Account__c            = acc.Id,
            Health_Score__c       = 55,
            Health_Status__c      = 'Em Risco',
            Open_Cases__c         = 4,
            NPS_Score__c          = 6,
            Payment_Delays__c     = 2,
            Last_Purchase_Days__c = 200
        );
    }

    @IsTest
    static void testEnqueue_opportunity() {
        Test.setMock(HttpCalloutMock.class, new OpenAIMock());
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;

        Test.startTest();
        AIInsightQueueable.enqueue(oppId, AIInsightService.TYPE_OPPORTUNITY);
        Test.stopTest();

        String result = [SELECT AI_Next_Step__c FROM Opportunity WHERE Id = :oppId].AI_Next_Step__c;
        Assert.areEqual('Insight via Queueable.', result, 'AI_Next_Step__c deve ser preenchido');
    }

    @IsTest
    static void testEnqueue_proposal() {
        Test.setMock(HttpCalloutMock.class, new OpenAIMock());
        Id propId = [SELECT Id FROM Product_Proposal__c LIMIT 1].Id;

        Test.startTest();
        AIInsightQueueable.enqueue(propId, AIInsightService.TYPE_PROPOSAL);
        Test.stopTest();

        String result = [SELECT AI_Summary__c FROM Product_Proposal__c WHERE Id = :propId].AI_Summary__c;
        Assert.isTrue(String.isNotBlank(result), 'AI_Summary__c deve ser preenchido');
    }

    @IsTest
    static void testEnqueue_health() {
        Test.setMock(HttpCalloutMock.class, new OpenAIMock());
        Id healthId = [SELECT Id FROM Customer_Health__c LIMIT 1].Id;

        Test.startTest();
        AIInsightQueueable.enqueue(healthId, AIInsightService.TYPE_HEALTH);
        Test.stopTest();

        String result = [SELECT AI_Health_Analysis__c FROM Customer_Health__c WHERE Id = :healthId].AI_Health_Analysis__c;
        Assert.isTrue(String.isNotBlank(result), 'AI_Health_Analysis__c deve ser preenchido');
    }

    @IsTest
    static void testEnqueue_tipoDesconhecido_naoLancaExcecao() {
        Test.setMock(HttpCalloutMock.class, new OpenAIMock());
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;

        Test.startTest();
        System.enqueueJob(new AIInsightQueueable(oppId, 'UNKNOWN_TYPE'));
        Test.stopTest();

        // Tipo desconhecido deve completar silenciosamente sem exceção
        Assert.areEqual(1, [SELECT COUNT() FROM Opportunity WHERE Id = :oppId]);
    }
}
