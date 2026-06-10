@IsTest
private class OpportunityApiResourceTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'OppAPI Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name      = 'OppAPI Prospecting',
            AccountId = acc.Id,
            Amount    = 75000,
            CloseDate = Date.today().addDays(30),
            StageName = 'Prospecting'
        );
        insert opp;

        Opportunity closedOpp = new Opportunity(
            Name      = 'OppAPI Closed Won',
            AccountId = acc.Id,
            Amount    = 120000,
            CloseDate = Date.today(),
            StageName = 'Closed Won'
        );
        insert closedOpp;
    }

    private static void setContext(String method, String uri) {
        RestRequest req = new RestRequest();
        req.requestURI = uri;
        req.httpMethod = method;
        RestContext.request  = req;
        RestContext.response = new RestResponse();
    }

    // ---- GET por ID ----

    @IsTest
    static void testGetById_encontrado() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'OppAPI Prospecting' LIMIT 1];
        setContext('GET', '/services/apexrest/smartsales/v1/opportunities/' + opp.Id);

        Test.startTest();
        OpportunityApiResource.doGet();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        String body = RestContext.response.responseBody.toString();
        System.assert(body.contains('"success":true'));
        System.assert(body.contains(opp.Id));
    }

    @IsTest
    static void testGetById_naoEncontrado() {
        Id fakeId = Opportunity.SObjectType.getDescribe().getKeyPrefix() + '000000000001AAA';
        setContext('GET', '/services/apexrest/smartsales/v1/opportunities/' + fakeId);

        Test.startTest();
        OpportunityApiResource.doGet();
        Test.stopTest();

        System.assertEquals(404, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('"success":false'));
    }

    // ---- GET lista ----

    @IsTest
    static void testGetLista_porAccountId() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'OppAPI Account' LIMIT 1];
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/smartsales/v1/opportunities/';
        req.httpMethod = 'GET';
        req.params.put('accountId', acc.Id);
        RestContext.request  = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        OpportunityApiResource.doGet();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('Closed Won'));
    }

    @IsTest
    static void testGetLista_semFiltro() {
        setContext('GET', '/services/apexrest/smartsales/v1/opportunities/');

        Test.startTest();
        OpportunityApiResource.doGet();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
    }

    // ---- POST ----

    @IsTest
    static void testPost_sucesso() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'OppAPI Account' LIMIT 1];
        RestRequest req = new RestRequest();
        req.requestURI  = '/services/apexrest/smartsales/v1/opportunities/';
        req.httpMethod  = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(new Opportunity(
            Name      = 'OppAPI Nova',
            AccountId = acc.Id,
            Amount    = 50000,
            CloseDate = Date.today().addDays(30),
            StageName = 'Qualification'
        )));
        RestContext.request  = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        OpportunityApiResource.doPost();
        Test.stopTest();

        System.assertEquals(201, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('"success":true'));
        System.assertEquals(1, [SELECT COUNT() FROM Opportunity WHERE Name = 'OppAPI Nova']);
    }

    @IsTest
    static void testPost_semCamposObrigatorios_retorna400() {
        RestRequest req = new RestRequest();
        req.requestURI  = '/services/apexrest/smartsales/v1/opportunities/';
        req.httpMethod  = 'POST';
        // Sem Name, CloseDate e StageName — DML vai falhar
        req.requestBody = Blob.valueOf('{"Amount":1000}');
        RestContext.request  = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        OpportunityApiResource.doPost();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }

    // ---- PATCH ----

    @IsTest
    static void testPatch_sucesso() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'OppAPI Prospecting' LIMIT 1];
        RestRequest req = new RestRequest();
        req.requestURI  = '/services/apexrest/smartsales/v1/opportunities/' + opp.Id;
        req.httpMethod  = 'PATCH';
        req.requestBody = Blob.valueOf(JSON.serialize(new Opportunity(
            StageName = 'Qualification',
            Amount    = 90000
        )));
        RestContext.request  = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        OpportunityApiResource.doPatch();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals('Qualification',
            [SELECT StageName FROM Opportunity WHERE Id = :opp.Id].StageName
        );
    }

    @IsTest
    static void testPatch_semId_retorna400() {
        setContext('PATCH', '/services/apexrest/smartsales/v1/opportunities/');
        RestContext.request.requestBody = Blob.valueOf(
            JSON.serialize(new Opportunity(StageName = 'Qualification'))
        );

        Test.startTest();
        OpportunityApiResource.doPatch();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }
}
