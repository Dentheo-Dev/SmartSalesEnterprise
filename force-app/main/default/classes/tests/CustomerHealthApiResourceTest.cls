@IsTest
private class CustomerHealthApiResourceTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'HealthAPI Account');
        insert acc;

        Customer_Health__c health = new Customer_Health__c(
            Name             = 'HealthAPI Record',
            Account__c       = acc.Id,
            Health_Score__c  = 85,
            Health_Status__c = 'Saudável',
            NPS_Score__c     = 8
        );
        insert health;
    }

    private static void setContext(String method, String uri) {
        RestRequest req = new RestRequest();
        req.requestURI = uri;
        req.httpMethod = method;
        RestContext.request  = req;
        RestContext.response = new RestResponse();
    }

    // ---- GET por AccountId ----

    @IsTest
    static void testGetByAccountId_encontrado() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'HealthAPI Account' LIMIT 1];
        setContext('GET', '/services/apexrest/smartsales/v1/health/' + acc.Id);

        Test.startTest();
        CustomerHealthApiResource.doGet();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        String body = RestContext.response.responseBody.toString();
        System.assert(body.contains('"success":true'));
        System.assert(body.contains(acc.Id), 'Deve conter o AccountId no body');
    }

    @IsTest
    static void testGetByAccountId_naoEncontrado() {
        Id fakeId = Account.SObjectType.getDescribe().getKeyPrefix() + '000000000001AAA';
        setContext('GET', '/services/apexrest/smartsales/v1/health/' + fakeId);

        Test.startTest();
        CustomerHealthApiResource.doGet();
        Test.stopTest();

        System.assertEquals(404, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('"success":false'));
    }

    @IsTest
    static void testGetSemAccountId_retorna400() {
        setContext('GET', '/services/apexrest/smartsales/v1/health/');

        Test.startTest();
        CustomerHealthApiResource.doGet();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('"success":false'));
    }
}
