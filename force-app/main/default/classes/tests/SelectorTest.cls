@IsTest
private class SelectorTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Selector Test Account');
        insert acc;

        // Opp aberta: Commission criada automaticamente pelo trigger (afterInsert)
        Opportunity opp = new Opportunity(
            Name      = 'Prospecting Opp',
            AccountId = acc.Id,
            Amount    = 50000,
            CloseDate = Date.today().addDays(30),
            StageName = 'Prospecting'
        );
        insert opp;

        // Opp Closed Won: Commission criada automaticamente pelo trigger
        Opportunity closedOpp = new Opportunity(
            Name      = 'Closed Won Opp',
            AccountId = acc.Id,
            Amount    = 100000,
            CloseDate = Date.today(),
            StageName = 'Closed Won'
        );
        insert closedOpp;

        // Lead com campos suficientes para score >= 50 após trigger de scoring
        // email corporativo(+20) + phone(+10) + LeadSource Web(+15) + CEO(+10) + 201-1000(+25) = 80
        Lead lead = new Lead(
            FirstName       = 'Test',
            LastName        = 'LeadSelector',
            Company         = 'SelectorCo',
            Email           = 'test.selector@selectorco.com',
            Phone           = '11999999999',
            LeadSource      = 'Web',
            Title           = 'CEO',
            Status          = 'Open - Not Contacted',
            Company_Size__c = '201-1000'
        );
        insert lead;

        Case c = new Case(
            AccountId = acc.Id,
            Subject   = 'Selector Test Case',
            Status    = 'New'
        );
        insert c;

        Customer_Health__c health = new Customer_Health__c(
            Name              = 'Selector Health',
            Account__c        = acc.Id,
            Health_Score__c   = 75,
            Health_Status__c  = 'Saudável',
            NPS_Score__c      = 9,
            Payment_Delays__c = 0,
            Open_Cases__c     = 1
        );
        insert health;

        Product_Proposal__c proposal = new Product_Proposal__c(
            Name           = 'PROP-SEL-001',
            Opportunity__c = opp.Id,
            Account__c     = acc.Id,
            Total_Value__c = 50000,
            Status__c      = 'Rascunho',
            Valid_Until__c = Date.today().addDays(30)
        );
        insert proposal;

        Product_Proposal__c expiredProposal = new Product_Proposal__c(
            Name           = 'PROP-SEL-EXP',
            Opportunity__c = opp.Id,
            Account__c     = acc.Id,
            Total_Value__c = 20000,
            Status__c      = 'Enviada',
            Valid_Until__c = Date.today().addDays(-5)
        );
        insert expiredProposal;
    }

    // ---- OpportunitySelector ----

    @IsTest
    static void testOpportunitySelectById() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Prospecting Opp' LIMIT 1];

        Test.startTest();
        List<Opportunity> results = OpportunitySelector.getInstance().selectById(new Set<Id>{ opp.Id });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(opp.Id, results[0].Id);
        System.assertEquals(50000, results[0].Amount);
    }

    @IsTest
    static void testOpportunitySelectByIdVazio() {
        Test.startTest();
        List<Opportunity> results = OpportunitySelector.getInstance().selectById(new Set<Id>());
        Test.stopTest();

        System.assertEquals(0, results.size());
    }

    @IsTest
    static void testOpportunitySelectSingleById() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Prospecting Opp' LIMIT 1];

        Test.startTest();
        Opportunity result = OpportunitySelector.getInstance().selectSingleById(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(opp.Id, result.Id);
        System.assertEquals(50000, result.Amount);
    }

    @IsTest
    static void testOpportunitySelectSingleByIdNaoEncontrado() {
        // Id de formato válido mas inexistente na org de teste
        Id fakeId = Opportunity.SObjectType.getDescribe().getKeyPrefix()
                  + '000000000001AAA';

        Test.startTest();
        Opportunity result = OpportunitySelector.getInstance().selectSingleById(fakeId);
        Test.stopTest();

        System.assertEquals(null, result, 'Deve retornar null para Id inexistente');
    }

    @IsTest
    static void testOpportunitySelectClosedWonByAccountIds() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Selector Test Account' LIMIT 1];

        Test.startTest();
        List<Opportunity> results = OpportunitySelector.getInstance()
            .selectClosedWonByAccountIds(new Set<Id>{ acc.Id });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals('Closed Won', results[0].StageName);
        System.assertEquals(acc.Id, results[0].AccountId);
    }

    @IsTest
    static void testOpportunitySelectClosedWonVazio() {
        Test.startTest();
        List<Opportunity> results = OpportunitySelector.getInstance()
            .selectClosedWonByAccountIds(new Set<Id>());
        Test.stopTest();

        System.assertEquals(0, results.size());
    }

    @IsTest
    static void testOpportunitySingletons() {
        OpportunitySelector a = OpportunitySelector.getInstance();
        OpportunitySelector b = OpportunitySelector.getInstance();
        System.assert(a == b, 'getInstance deve retornar a mesma instância na transação');
        System.assertEquals(Opportunity.SObjectType, a.getSObjectType());
        System.assert(!a.getSObjectFieldList().isEmpty());
    }

    // ---- LeadSelector ----

    @IsTest
    static void testLeadSelectById() {
        Lead lead = [SELECT Id FROM Lead WHERE LastName = 'LeadSelector' LIMIT 1];

        Test.startTest();
        List<Lead> results = LeadSelector.getInstance().selectById(new Set<Id>{ lead.Id });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(lead.Id, results[0].Id);
    }

    @IsTest
    static void testLeadSelectByIdVazio() {
        Test.startTest();
        List<Lead> results = LeadSelector.getInstance().selectById(new Set<Id>());
        Test.stopTest();

        System.assertEquals(0, results.size());
    }

    @IsTest
    static void testLeadSelectByStatus() {
        Test.startTest();
        List<Lead> results = LeadSelector.getInstance().selectByStatus('Open - Not Contacted');
        Test.stopTest();

        System.assert(!results.isEmpty());
        for (Lead l : results) {
            System.assertEquals('Open - Not Contacted', l.Status);
        }
    }

    @IsTest
    static void testLeadSelectUnconvertedByMinScore() {
        // Trigger de scoring calcula 80 para este lead no setup
        Test.startTest();
        List<Lead> comScore = LeadSelector.getInstance().selectUnconvertedByMinScore(0);
        List<Lead> semScore = LeadSelector.getInstance().selectUnconvertedByMinScore(101);
        Test.stopTest();

        System.assert(!comScore.isEmpty(), 'Deve retornar leads com score >= 0');
        System.assertEquals(0, semScore.size(), 'Score 101 é impossível — nenhum resultado');
        for (Lead l : comScore) {
            System.assert(l.Lead_Score__c >= 0);
        }
    }

    @IsTest
    static void testLeadSingletons() {
        LeadSelector a = LeadSelector.getInstance();
        LeadSelector b = LeadSelector.getInstance();
        System.assert(a == b);
        System.assertEquals(Lead.SObjectType, a.getSObjectType());
        System.assert(!a.getSObjectFieldList().isEmpty());
    }

    // ---- CaseSelector ----

    @IsTest
    static void testCaseSelectById() {
        Case c = [SELECT Id FROM Case WHERE Subject = 'Selector Test Case' LIMIT 1];

        Test.startTest();
        List<Case> results = CaseSelector.getInstance().selectById(new Set<Id>{ c.Id });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(c.Id, results[0].Id);
        System.assertEquals(false, results[0].IsClosed);
    }

    @IsTest
    static void testCaseSelectOpenCasesCountByAccountIds() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Selector Test Account' LIMIT 1];

        Test.startTest();
        List<AggregateResult> results = CaseSelector.getInstance()
            .selectOpenCasesCountByAccountIds(new Set<Id>{ acc.Id });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(acc.Id, (Id) results[0].get('AccountId'));
        System.assertEquals(1, Integer.valueOf(results[0].get('total')));
    }

    @IsTest
    static void testCaseOpenCasesCountVazio() {
        Test.startTest();
        List<AggregateResult> results = CaseSelector.getInstance()
            .selectOpenCasesCountByAccountIds(new Set<Id>());
        Test.stopTest();

        System.assertEquals(0, results.size());
    }

    @IsTest
    static void testCaseSingletons() {
        CaseSelector a = CaseSelector.getInstance();
        CaseSelector b = CaseSelector.getInstance();
        System.assert(a == b);
        System.assertEquals(Case.SObjectType, a.getSObjectType());
        System.assert(!a.getSObjectFieldList().isEmpty());
    }

    // ---- CustomerHealthSelector ----

    @IsTest
    static void testHealthSelectLatestByAccountIds() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Selector Test Account' LIMIT 1];

        Test.startTest();
        Map<Id, Customer_Health__c> result = CustomerHealthSelector.getInstance()
            .selectLatestByAccountIds(new Set<Id>{ acc.Id });
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assert(result.containsKey(acc.Id));
        System.assertEquals(75, result.get(acc.Id).Health_Score__c);
        System.assertEquals(9, result.get(acc.Id).NPS_Score__c);
    }

    @IsTest
    static void testHealthSelectLatestRetornaUmPorAccount() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Selector Test Account' LIMIT 1];

        // Segundo registro de saúde para a mesma account
        Customer_Health__c second = new Customer_Health__c(
            Name             = 'Selector Health 2',
            Account__c       = acc.Id,
            Health_Score__c  = 50,
            Health_Status__c = 'Em Risco'
        );
        insert second;

        Test.startTest();
        Map<Id, Customer_Health__c> result = CustomerHealthSelector.getInstance()
            .selectLatestByAccountIds(new Set<Id>{ acc.Id });
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Deve retornar apenas o mais recente por account');
    }

    @IsTest
    static void testHealthSelectLatestVazio() {
        Test.startTest();
        Map<Id, Customer_Health__c> result = CustomerHealthSelector.getInstance()
            .selectLatestByAccountIds(new Set<Id>());
        Test.stopTest();

        System.assertEquals(0, result.size());
    }

    @IsTest
    static void testHealthSingletons() {
        CustomerHealthSelector a = CustomerHealthSelector.getInstance();
        CustomerHealthSelector b = CustomerHealthSelector.getInstance();
        System.assert(a == b);
        System.assertEquals(Customer_Health__c.SObjectType, a.getSObjectType());
        System.assert(!a.getSObjectFieldList().isEmpty());
    }

    // ---- CommissionSelector ----

    @IsTest
    static void testCommissionSelectByOpportunityIds() {
        // Commission criada automaticamente pelo trigger ao inserir a Opp
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Prospecting Opp' LIMIT 1];

        Test.startTest();
        Map<Id, Commission__c> result = CommissionSelector.getInstance()
            .selectByOpportunityIds(new Set<Id>{ opp.Id });
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assert(result.containsKey(opp.Id));
    }

    @IsTest
    static void testCommissionSelectByOpportunityIdsVazio() {
        Test.startTest();
        Map<Id, Commission__c> result = CommissionSelector.getInstance()
            .selectByOpportunityIds(new Set<Id>());
        Test.stopTest();

        System.assertEquals(0, result.size());
    }

    @IsTest
    static void testCommissionSingletons() {
        CommissionSelector a = CommissionSelector.getInstance();
        CommissionSelector b = CommissionSelector.getInstance();
        System.assert(a == b);
        System.assertEquals(Commission__c.SObjectType, a.getSObjectType());
        System.assert(!a.getSObjectFieldList().isEmpty());
    }

    // ---- ProductProposalSelector ----

    @IsTest
    static void testProposalSelectById() {
        Product_Proposal__c prop = [
            SELECT Id FROM Product_Proposal__c WHERE Name = 'PROP-SEL-001' LIMIT 1
        ];

        Test.startTest();
        Product_Proposal__c result = ProductProposalSelector.getInstance().selectById(prop.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(prop.Id, result.Id);
        System.assertEquals('Rascunho', result.Status__c);
        System.assertEquals(50000, result.Total_Value__c);
    }

    @IsTest
    static void testProposalSelectExpiredSent() {
        Test.startTest();
        List<Product_Proposal__c> results = ProductProposalSelector.getInstance().selectExpiredSent();
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals('Enviada', results[0].Status__c);
    }

    @IsTest
    static void testProposalSelectExpiredIgnoraRascunho() {
        // O 'PROP-SEL-001' está como Rascunho e vencido não existe no setup
        // Verifica que apenas Enviada + vencida são retornadas
        Test.startTest();
        List<Product_Proposal__c> results = ProductProposalSelector.getInstance().selectExpiredSent();
        Test.stopTest();

        for (Product_Proposal__c p : results) {
            System.assertEquals('Enviada', p.Status__c, 'Apenas status Enviada deve ser retornado');
        }
    }

    @IsTest
    static void testProposalSingletons() {
        ProductProposalSelector a = ProductProposalSelector.getInstance();
        ProductProposalSelector b = ProductProposalSelector.getInstance();
        System.assert(a == b);
        System.assertEquals(Product_Proposal__c.SObjectType, a.getSObjectType());
        System.assert(!a.getSObjectFieldList().isEmpty());
    }
}
