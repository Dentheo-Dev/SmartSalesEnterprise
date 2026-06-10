@IsTest
private class IntegrationLogServiceTest {

    @IsTest
    static void testBuildLog_success() {
        Integration_Log__c log = IntegrationLogService.buildLog(
            'TestService', '{"key":"val"}', '{"result":"ok"}',
            200, true, 123L, 'a0000000000000A', null
        );

        Assert.areEqual('TestService', log.Service_Name__c);
        Assert.areEqual('{"key":"val"}', log.Request_Body__c);
        Assert.areEqual('{"result":"ok"}', log.Response_Body__c);
        Assert.areEqual(200, Integer.valueOf(log.Status_Code__c));
        Assert.isTrue(log.Success__c);
        Assert.areEqual(123, Long.valueOf(String.valueOf(log.Duration_Ms__c)));
        Assert.areEqual('a0000000000000A', log.Related_Record_Id__c);
        Assert.isNull(log.Error_Message__c);
        Assert.isNotNull(log.Created_At__c);
    }

    @IsTest
    static void testBuildLog_falha() {
        Integration_Log__c log = IntegrationLogService.buildLog(
            'TestService', null, null,
            500, false, 50L, null, 'Timeout reached'
        );

        Assert.isFalse(log.Success__c);
        Assert.areEqual('Timeout reached', log.Error_Message__c);
        Assert.isNull(log.Request_Body__c);
        Assert.isNull(log.Response_Body__c);
        Assert.isNull(log.Related_Record_Id__c);
    }

    @IsTest
    static void testBuildLog_truncaTextoLongo() {
        String textoGrande = 'x'.repeat(40000);
        Integration_Log__c log = IntegrationLogService.buildLog(
            'TestService', textoGrande, textoGrande,
            200, true, 10L, null, textoGrande
        );

        Assert.areEqual(32768, log.Request_Body__c.length());
        Assert.areEqual(32768, log.Response_Body__c.length());
        Assert.areEqual(32768, log.Error_Message__c.length());
    }

    @IsTest
    static void testSave_insereDois() {
        List<Integration_Log__c> logs = new List<Integration_Log__c>{
            IntegrationLogService.buildLog('A', 'req', 'res', 200, true,  10L, null, null),
            IntegrationLogService.buildLog('B', 'req', 'res', 500, false, 20L, null, 'err')
        };

        Test.startTest();
        IntegrationLogService.save(logs);
        Test.stopTest();

        Assert.areEqual(2, [SELECT COUNT() FROM Integration_Log__c]);
    }

    @IsTest
    static void testSave_listaVazia() {
        Test.startTest();
        IntegrationLogService.save(new List<Integration_Log__c>());
        Test.stopTest();
        Assert.areEqual(0, [SELECT COUNT() FROM Integration_Log__c]);
    }

    @IsTest
    static void testSave_null() {
        Test.startTest();
        IntegrationLogService.save(null);
        Test.stopTest();
        Assert.areEqual(0, [SELECT COUNT() FROM Integration_Log__c]);
    }
}
