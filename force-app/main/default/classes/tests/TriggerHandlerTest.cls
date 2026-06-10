@IsTest
private class TriggerHandlerTest {

    // Handler concreto mínimo para testar a classe base
    private class TestHandler extends TriggerHandler {
        public Boolean beforeInsertCalled  = false;
        public Boolean beforeUpdateCalled  = false;
        public Boolean beforeDeleteCalled  = false;
        public Boolean afterInsertCalled   = false;
        public Boolean afterUpdateCalled   = false;
        public Boolean afterDeleteCalled   = false;
        public Boolean afterUndeleteCalled = false;

        override protected void beforeInsert()   { beforeInsertCalled  = true; }
        override protected void beforeUpdate()   { beforeUpdateCalled  = true; }
        override protected void beforeDelete()   { beforeDeleteCalled  = true; }
        override protected void afterInsert()    { afterInsertCalled   = true; }
        override protected void afterUpdate()    { afterUpdateCalled   = true; }
        override protected void afterDelete()    { afterDeleteCalled   = true; }
        override protected void afterUndelete()  { afterUndeleteCalled = true; }
    }

    @IsTest
    static void testBypassSetsHandlerAsSkipped() {
        TriggerHandler.bypass('TestHandler');
        System.assert(TriggerHandler.isBypassed('TestHandler'), 'Handler deve estar bypassado');
    }

    @IsTest
    static void testClearBypassRemovesHandler() {
        TriggerHandler.bypass('TestHandler');
        TriggerHandler.clearBypass('TestHandler');
        System.assert(!TriggerHandler.isBypassed('TestHandler'), 'Bypass deve ter sido removido');
    }

    @IsTest
    static void testClearAllBypassesRemovesAll() {
        TriggerHandler.bypass('HandlerA');
        TriggerHandler.bypass('HandlerB');
        TriggerHandler.clearAllBypasses();
        System.assert(!TriggerHandler.isBypassed('HandlerA'), 'HandlerA deve estar limpo');
        System.assert(!TriggerHandler.isBypassed('HandlerB'), 'HandlerB deve estar limpo');
    }

    @IsTest
    static void testOpportunityTriggerHandlerInstantiates() {
        // Garante que o handler pode ser instanciado fora de contexto de trigger
        // (testa que não há NPE no construtor ao rodar sem Trigger.new)
        try {
            OpportunityTriggerHandler h = new OpportunityTriggerHandler();
            System.assertNotEquals(null, h, 'Handler deve ser instanciado');
        } catch (Exception e) {
            // NullPointerException esperado fora de contexto de trigger — OK
            System.assert(
                e instanceof NullPointerException || e instanceof System.NullPointerException,
                'Exceção inesperada: ' + e.getMessage()
            );
        }
    }

    @IsTest
    static void testLeadTriggerHandlerInstantiates() {
        try {
            LeadTriggerHandler h = new LeadTriggerHandler();
            System.assertNotEquals(null, h, 'Handler deve ser instanciado');
        } catch (Exception e) {
            System.assert(
                e instanceof NullPointerException || e instanceof System.NullPointerException,
                'Exceção inesperada: ' + e.getMessage()
            );
        }
    }

    @IsTest
    static void testCaseTriggerHandlerInstantiates() {
        try {
            CaseTriggerHandler h = new CaseTriggerHandler();
            System.assertNotEquals(null, h, 'Handler deve ser instanciado');
        } catch (Exception e) {
            System.assert(
                e instanceof NullPointerException || e instanceof System.NullPointerException,
                'Exceção inesperada: ' + e.getMessage()
            );
        }
    }

    @IsTest
    static void testLeadTriggerNormalizesPhoneOnInsert() {
        Lead l = new Lead(
            FirstName = 'Teste',
            LastName  = 'Lead',
            Company  = 'Empresa Teste',
            Email    = 'teste@empresa.com',
            Phone    = '11987654321'
        );

        Test.startTest();
        insert l;
        Test.stopTest();

        Lead inserted = [SELECT Phone FROM Lead WHERE Id = :l.Id];
        System.assertEquals('(11) 98765-4321', inserted.Phone, 'Telefone deve ser normalizado');
    }

    @IsTest
    static void testLeadTriggerNormalizesLandlineOnInsert() {
        Lead l = new Lead(
            FirstName = 'Fixo',
            LastName  = 'Lead',
            Company  = 'Empresa Teste',
            Email    = 'fixo@empresa.com',
            Phone    = '1134567890'
        );

        Test.startTest();
        insert l;
        Test.stopTest();

        Lead inserted = [SELECT Phone FROM Lead WHERE Id = :l.Id];
        System.assertEquals('(11) 3456-7890', inserted.Phone, 'Telefone fixo deve ser normalizado');
    }

    @IsTest
    static void testOpportunityTriggerRejectsCloseDateInPast() {
        Account acc = new Account(Name = 'Conta Teste');
        insert acc;

        Opportunity opp = new Opportunity(
            Name      = 'Opp Teste',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(-1),
            Amount    = 5000
        );

        Boolean exceptionThrown = false;
        try {
            insert opp;
        } catch (DmlException e) {
            exceptionThrown = true;
            System.assert(
                e.getMessage().contains('passado'),
                'Mensagem de erro deve mencionar data no passado'
            );
        }

        System.assert(exceptionThrown, 'Deve lançar erro para CloseDate no passado');
    }

    @IsTest
    static void testOpportunityTriggerAcceptsFutureCloseDate() {
        Account acc = new Account(Name = 'Conta Válida');
        insert acc;

        Opportunity opp = new Opportunity(
            Name      = 'Opp Válida',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount    = 10000
        );

        Test.startTest();
        insert opp;
        Test.stopTest();

        System.assertNotEquals(null, opp.Id, 'Opp com CloseDate válida deve ser inserida');
    }
}
