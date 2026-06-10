@IsTest
private class ViaCEPCalloutServiceTest {

    private static final String RESP_VALID = '{"cep":"01310-100","logradouro":"Avenida Paulista","complemento":"de 1 a 610 - lado par","bairro":"Bela Vista","localidade":"São Paulo","uf":"SP","ibge":"3550308","gia":"1004","ddd":"11","siafi":"7107"}';
    private static final String RESP_ERRO  = '{"erro":"true"}';

    private class ViaCEPMock implements HttpCalloutMock {
        private Integer statusCode;
        private String  body;

        ViaCEPMock(Integer statusCode, String body) {
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

    // Sem @TestSetup: cada teste cria seu Account para controlar o mock antes do trigger disparar

    @IsTest
    static void testEnrichAddress_success() {
        Test.setMock(HttpCalloutMock.class, new ViaCEPMock(200, RESP_VALID));
        Account acc = new Account(Name = 'Empresa Teste', CEP__c = '01310-100');

        Test.startTest();
        insert acc; // AccountTrigger → enrichAddressAsync queued
        Test.stopTest(); // @future executa com o mock

        Account updated = [SELECT BillingCity, Bairro__c, BillingPostalCode FROM Account WHERE Id = :acc.Id];
        Assert.areEqual('São Paulo', updated.BillingCity);
        Assert.areEqual('Bela Vista', updated.Bairro__c);
        Assert.areEqual('01310100', updated.BillingPostalCode);

        List<Integration_Log__c> logs = [SELECT Success__c FROM Integration_Log__c WHERE Service_Name__c = 'ViaCEP'];
        Assert.isFalse(logs.isEmpty(), 'Deve gerar log');
        Assert.isTrue(logs[0].Success__c);
    }

    @IsTest
    static void testEnrichAddress_cepNotFound() {
        Test.setMock(HttpCalloutMock.class, new ViaCEPMock(200, RESP_ERRO));
        Account acc = new Account(Name = 'Empresa Teste', CEP__c = '99999999');

        Test.startTest();
        insert acc;
        Test.stopTest();

        List<Integration_Log__c> logs = [
            SELECT Success__c, Error_Message__c
            FROM Integration_Log__c
            WHERE Service_Name__c = 'ViaCEP'
        ];
        Assert.isFalse(logs.isEmpty());
        Assert.isFalse(logs[0].Success__c);
        Assert.isTrue(logs[0].Error_Message__c.contains('CEP não encontrado'));
    }

    @IsTest
    static void testEnrichAddress_httpError() {
        Test.setMock(HttpCalloutMock.class, new ViaCEPMock(503, 'Service Unavailable'));
        Account acc = new Account(Name = 'Empresa Teste', CEP__c = '01310-100');

        Test.startTest();
        insert acc;
        Test.stopTest();

        List<Integration_Log__c> logs = [
            SELECT Success__c, Status_Code__c
            FROM Integration_Log__c
            WHERE Service_Name__c = 'ViaCEP'
        ];
        Assert.isFalse(logs.isEmpty());
        Assert.isFalse(logs[0].Success__c);
        Assert.areEqual(503, Integer.valueOf(logs[0].Status_Code__c));
    }

    @IsTest
    static void testEnrichAddress_emptyList() {
        Test.startTest();
        ViaCEPCalloutService.enrichAddress(new List<Account>());
        Test.stopTest();
        Assert.areEqual(0, [SELECT COUNT() FROM Integration_Log__c]);
    }

    @IsTest
    static void testEnrichAddress_cepInvalido() {
        // CEP com menos de 8 dígitos é ignorado silenciosamente — sem callout, sem log
        Account acc = new Account(Name = 'Empresa Teste', CEP__c = '123');

        Test.startTest();
        insert acc; // AccountTrigger dispara mas o CEP inválido é filtrado dentro do @future
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM Integration_Log__c], 'CEP inválido não deve gerar log');
    }
}
