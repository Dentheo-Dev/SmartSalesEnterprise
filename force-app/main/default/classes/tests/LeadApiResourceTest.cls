@IsTest
private class LeadApiResourceTest {

    @TestSetup
    static void setup() {
        Lead lead = new Lead(
            FirstName       = 'API',
            LastName        = 'TestLead',
            Company         = 'TestCo',
            Email           = 'api.test@testco.com',
            Status          = 'Open - Not Contacted',
            LeadSource      = 'Web',
            Phone           = '11999999999',
            Title           = 'CEO',
            Company_Size__c = '201-1000'
        );
        insert lead;
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
        Lead lead = [SELECT Id FROM Lead WHERE LastName = 'TestLead' LIMIT 1];
        setContext('GET', '/services/apexrest/smartsales/v1/leads/' + lead.Id);

        Test.startTest();
        LeadApiResource.doGet();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        String body = RestContext.response.responseBody.toString();
        System.assert(body.contains('"success":true'), 'Deve conter success:true');
        System.assert(body.contains(lead.Id), 'Deve conter o Id do lead');
    }

    @IsTest
    static void testGetById_naoEncontrado() {
        Id fakeId = Lead.SObjectType.getDescribe().getKeyPrefix() + '000000000001AAA';
        setContext('GET', '/services/apexrest/smartsales/v1/leads/' + fakeId);

        Test.startTest();
        LeadApiResource.doGet();
        Test.stopTest();

        System.assertEquals(404, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('"success":false'));
    }

    // ---- GET lista ----

    @IsTest
    static void testGetLista_porStatus() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/smartsales/v1/leads/';
        req.httpMethod = 'GET';
        req.params.put('status', 'Open - Not Contacted');
        RestContext.request  = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        LeadApiResource.doGet();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('"success":true'));
    }

    @IsTest
    static void testGetLista_porMinScore() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/smartsales/v1/leads/';
        req.httpMethod = 'GET';
        req.params.put('minScore', '0');
        RestContext.request  = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        LeadApiResource.doGet();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
    }

    @IsTest
    static void testGetLista_semFiltro() {
        setContext('GET', '/services/apexrest/smartsales/v1/leads/');

        Test.startTest();
        LeadApiResource.doGet();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
    }

    // ---- POST ----

    @IsTest
    static void testPost_sucesso() {
        RestRequest req = new RestRequest();
        req.requestURI  = '/services/apexrest/smartsales/v1/leads/';
        req.httpMethod  = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(new Lead(
            FirstName = 'New',
            LastName  = 'ApiLead',
            Company   = 'NewCo',
            Status    = 'Open - Not Contacted'
        )));
        RestContext.request  = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        LeadApiResource.doPost();
        Test.stopTest();

        System.assertEquals(201, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('"success":true'));
        System.assertEquals(1, [SELECT COUNT() FROM Lead WHERE LastName = 'ApiLead']);
    }

    @IsTest
    static void testPost_semLastName_retorna400() {
        RestRequest req = new RestRequest();
        req.requestURI  = '/services/apexrest/smartsales/v1/leads/';
        req.httpMethod  = 'POST';
        // Lead sem LastName e sem Company — DML vai falhar
        req.requestBody = Blob.valueOf('{"Phone":"11900000000"}');
        RestContext.request  = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        LeadApiResource.doPost();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('"success":false'));
    }

    // ---- PATCH ----

    @IsTest
    static void testPatch_sucesso() {
        Lead lead = [SELECT Id FROM Lead WHERE LastName = 'TestLead' LIMIT 1];
        RestRequest req = new RestRequest();
        req.requestURI  = '/services/apexrest/smartsales/v1/leads/' + lead.Id;
        req.httpMethod  = 'PATCH';
        req.requestBody = Blob.valueOf(JSON.serialize(new Lead(Company = 'UpdatedCo')));
        RestContext.request  = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        LeadApiResource.doPatch();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals('UpdatedCo', [SELECT Company FROM Lead WHERE Id = :lead.Id].Company);
    }

    @IsTest
    static void testPatch_semId_retorna400() {
        setContext('PATCH', '/services/apexrest/smartsales/v1/leads/');
        RestContext.request.requestBody = Blob.valueOf(JSON.serialize(new Lead(Company = 'X')));

        Test.startTest();
        LeadApiResource.doPatch();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }

    // ---- DELETE ----

    @IsTest
    static void testDelete_sucesso() {
        Lead lead = [SELECT Id FROM Lead WHERE LastName = 'TestLead' LIMIT 1];
        setContext('DELETE', '/services/apexrest/smartsales/v1/leads/' + lead.Id);

        Test.startTest();
        LeadApiResource.doDelete();
        Test.stopTest();

        System.assertEquals(204, RestContext.response.statusCode);
        System.assertEquals(0, [SELECT COUNT() FROM Lead WHERE Id = :lead.Id]);
    }

    @IsTest
    static void testDelete_semId_retorna400() {
        setContext('DELETE', '/services/apexrest/smartsales/v1/leads/');

        Test.startTest();
        LeadApiResource.doDelete();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }
}
