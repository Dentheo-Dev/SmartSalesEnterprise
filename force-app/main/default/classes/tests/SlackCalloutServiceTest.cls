@IsTest
private class SlackCalloutServiceTest {

    private class SlackMock implements HttpCalloutMock {
        private Integer statusCode;
        private String  body;

        SlackMock(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body       = body;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(body);
            return res;
        }
    }

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Acme Corp');
        insert acc;

        insert new Opportunity(
            Name      = 'Venda Teste',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount    = 50000,
            AccountId = acc.Id
        );
    }

    @IsTest
    static void testNotifyClosedWon_success() {
        Test.setMock(HttpCalloutMock.class, new SlackMock(200, 'ok'));
        Opportunity opp = [SELECT Id, Name, Amount, AccountId FROM Opportunity LIMIT 1];

        Test.startTest();
        SlackCalloutService.notifyClosedWon(new List<Opportunity>{ opp });
        Test.stopTest();

        List<Integration_Log__c> logs = [
            SELECT Success__c, Status_Code__c
            FROM Integration_Log__c
            WHERE Service_Name__c = 'Slack_ClosedWon'
        ];
        Assert.isFalse(logs.isEmpty(), 'Deve criar log de integração');
        Assert.isTrue(logs[0].Success__c, 'Log deve indicar sucesso');
        Assert.areEqual(200, Integer.valueOf(logs[0].Status_Code__c));
    }

    @IsTest
    static void testNotifyClosedWon_httpError() {
        Test.setMock(HttpCalloutMock.class, new SlackMock(500, 'Internal Server Error'));
        Opportunity opp = [SELECT Id, Name, Amount, AccountId FROM Opportunity LIMIT 1];

        Test.startTest();
        SlackCalloutService.notifyClosedWon(new List<Opportunity>{ opp });
        Test.stopTest();

        List<Integration_Log__c> logs = [
            SELECT Success__c, Status_Code__c, Error_Message__c
            FROM Integration_Log__c
            WHERE Service_Name__c = 'Slack_ClosedWon'
        ];
        Assert.isFalse(logs.isEmpty(), 'Deve criar log mesmo em falha');
        Assert.isFalse(logs[0].Success__c, 'Log deve indicar falha');
        Assert.areEqual(500, Integer.valueOf(logs[0].Status_Code__c));
        Assert.isTrue(logs[0].Error_Message__c.contains('500'));
    }

    @IsTest
    static void testNotifyClosedWon_emptyList() {
        Test.startTest();
        SlackCalloutService.notifyClosedWon(new List<Opportunity>());
        Test.stopTest();
        // Lista vazia não lança exceção e não gera callout
        Assert.areEqual(0, [SELECT COUNT() FROM Integration_Log__c]);
    }

    @IsTest
    static void testNotifyClosedWon_nullList() {
        Test.startTest();
        SlackCalloutService.notifyClosedWon(null);
        Test.stopTest();
        Assert.areEqual(0, [SELECT COUNT() FROM Integration_Log__c]);
    }
}
