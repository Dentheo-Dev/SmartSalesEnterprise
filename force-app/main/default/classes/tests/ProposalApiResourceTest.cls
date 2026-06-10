@IsTest
private class ProposalApiResourceTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'ProposalAPI Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name      = 'ProposalAPI Opp',
            AccountId = acc.Id,
            Amount    = 60000,
            CloseDate = Date.today().addDays(30),
            StageName = 'Prospecting'
        );
        insert opp;

        Product_Proposal__c proposal = new Product_Proposal__c(
            Name           = 'PROP-API-001',
            Opportunity__c = opp.Id,
            Account__c     = acc.Id,
            Total_Value__c = 60000,
            Status__c      = 'Rascunho',
            Valid_Until__c = Date.today().addDays(30)
        );
        insert proposal;
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
        Product_Proposal__c prop = [
            SELECT Id FROM Product_Proposal__c WHERE Name = 'PROP-API-001' LIMIT 1
        ];
        setContext('GET', '/services/apexrest/smartsales/v1/proposals/' + prop.Id);

        Test.startTest();
        ProposalApiResource.doGet();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        String body = RestContext.response.responseBody.toString();
        System.assert(body.contains('"success":true'));
        System.assert(body.contains(prop.Id));
    }

    @IsTest
    static void testGetById_naoEncontrado() {
        Id fakeId = Product_Proposal__c.SObjectType.getDescribe().getKeyPrefix() + '000000000001AAA';
        setContext('GET', '/services/apexrest/smartsales/v1/proposals/' + fakeId);

        Test.startTest();
        ProposalApiResource.doGet();
        Test.stopTest();

        System.assertEquals(404, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('"success":false'));
    }

    @IsTest
    static void testGetSemId_retorna400() {
        setContext('GET', '/services/apexrest/smartsales/v1/proposals/');

        Test.startTest();
        ProposalApiResource.doGet();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }

    // ---- POST ----

    @IsTest
    static void testPost_sucesso() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'ProposalAPI Account' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'ProposalAPI Opp' LIMIT 1];

        RestRequest req = new RestRequest();
        req.requestURI  = '/services/apexrest/smartsales/v1/proposals/';
        req.httpMethod  = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(new Product_Proposal__c(
            Name           = 'PROP-API-002',
            Opportunity__c = opp.Id,
            Account__c     = acc.Id,
            Total_Value__c = 30000,
            Status__c      = 'Rascunho',
            Valid_Until__c = Date.today().addDays(15)
        )));
        RestContext.request  = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        ProposalApiResource.doPost();
        Test.stopTest();

        System.assertEquals(201, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('"success":true'));
        System.assertEquals(1,
            [SELECT COUNT() FROM Product_Proposal__c WHERE Name = 'PROP-API-002']
        );
    }

    @IsTest
    static void testPost_jsonInvalido_retorna400() {
        RestRequest req = new RestRequest();
        req.requestURI  = '/services/apexrest/smartsales/v1/proposals/';
        req.httpMethod  = 'POST';
        // JSON malformado — JSON.deserialize vai lançar exceção
        req.requestBody = Blob.valueOf('not valid json {{{{');
        RestContext.request  = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        ProposalApiResource.doPost();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('"success":false'));
    }
}
