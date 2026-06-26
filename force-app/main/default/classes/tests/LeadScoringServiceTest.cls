@IsTest
private class LeadScoringServiceTest {

    @TestSetup
    static void setup() {
        List<Lead> leads = new List<Lead>();

        // Lead com todos os critérios de pontuação
        leads.add(new Lead(
            FirstName                  = 'João',
            LastName                   = 'Silva',
            Company                    = 'TechCorp',
            Email                      = 'joao.silva@techcorp.com.br',
            Phone                      = '(11) 99999-9999',
            Title                      = 'CEO',
            LeadSource                 = 'Web',
            Company_Size__c            = '201-1000',
            Annual_Revenue_Estimate__c = 5000000
        ));

        // Lead sem nenhum critério de pontuação
        leads.add(new Lead(
            FirstName = 'Maria',
            LastName  = 'Santos',
            Company   = 'StartupX',
            Email     = 'maria@gmail.com'
        ));

        insert leads;
    }

    @IsTest
    static void testScoreMaximo() {
        Lead lead = [
            SELECT Id, Email, Phone, Title, LeadSource,
                   Company_Size__c, Annual_Revenue_Estimate__c, Lead_Score__c
            FROM Lead
            WHERE LastName = 'Silva'
            LIMIT 1
        ];

        Test.startTest();
        LeadScoringService.scoreLeads(new List<Lead>{ lead });
        Test.stopTest();

        Lead scored = [SELECT Lead_Score__c, Score_Reason__c FROM Lead WHERE Id = :lead.Id];
        System.assertEquals(100, scored.Lead_Score__c, 'Score máximo esperado: 100');
        System.assert(String.isNotBlank(scored.Score_Reason__c), 'Score_Reason__c deve ser preenchido');
        System.assert(scored.Score_Reason__c.contains('+20'), 'Deve conter crédito de email corporativo');
    }

    @IsTest
    static void testScoreZero() {
        Lead lead = [
            SELECT Id, Email, Phone, Title, LeadSource,
                   Company_Size__c, Annual_Revenue_Estimate__c, Lead_Score__c
            FROM Lead WHERE LastName = 'Santos' LIMIT 1
        ];

        Test.startTest();
        LeadScoringService.scoreLeads(new List<Lead>{ lead });
        Test.stopTest();

        Lead scored = [SELECT Lead_Score__c FROM Lead WHERE Id = :lead.Id];
        System.assertEquals(0, scored.Lead_Score__c, 'Score zero esperado — sem nenhum critério');
    }

    @IsTest
    static void testEmailCorporativoIsolado() {
        Lead lead = new Lead(
            FirstName = 'Corp', LastName = 'Email',
            Company   = 'CorpInc',
            Email     = 'usuario@corporateinc.com'
        );
        insert lead;

        lead = [
            SELECT Id, Email, Phone, Title, LeadSource,
                   Company_Size__c, Annual_Revenue_Estimate__c, Lead_Score__c
            FROM Lead WHERE Id = :lead.Id
        ];

        Test.startTest();
        LeadScoringService.scoreLeads(new List<Lead>{ lead });
        Test.stopTest();

        Lead scored = [SELECT Lead_Score__c FROM Lead WHERE Id = :lead.Id];
        System.assertEquals(20, scored.Lead_Score__c, 'Apenas +20 por email corporativo');
    }

    @IsTest
    static void testCargoExecutivo() {
        Lead lead = new Lead(
            FirstName = 'Exec', LastName = 'Title',
            Company   = 'ExecCo',
            Email     = 'exec@gmail.com',
            Title     = 'VP of Sales'
        );
        insert lead;

        lead = [
            SELECT Id, Email, Phone, Title, LeadSource,
                   Company_Size__c, Annual_Revenue_Estimate__c, Lead_Score__c
            FROM Lead WHERE Id = :lead.Id
        ];

        Test.startTest();
        LeadScoringService.scoreLeads(new List<Lead>{ lead });
        Test.stopTest();

        Lead scored = [SELECT Lead_Score__c FROM Lead WHERE Id = :lead.Id];
        System.assertEquals(10, scored.Lead_Score__c, '+10 por cargo executivo');
    }

    @IsTest
    static void testOrigemReferral() {
        Lead lead = new Lead(
            FirstName  = 'Ref', LastName = 'Source',
            Company    = 'RefCo',
            Email      = 'ref@gmail.com',
            LeadSource = 'Referral'
        );
        insert lead;

        lead = [
            SELECT Id, Email, Phone, Title, LeadSource,
                   Company_Size__c, Annual_Revenue_Estimate__c, Lead_Score__c
            FROM Lead WHERE Id = :lead.Id
        ];

        Test.startTest();
        LeadScoringService.scoreLeads(new List<Lead>{ lead });
        Test.stopTest();

        Lead scored = [SELECT Lead_Score__c FROM Lead WHERE Id = :lead.Id];
        System.assertEquals(15, scored.Lead_Score__c, '+15 por origem Referral');
    }

    @IsTest
    static void testScoreNaoUltrapassaCem() {
        Lead lead = new Lead(
            FirstName                  = 'Max', LastName = 'Score',
            Company                    = 'MaxCo',
            Email                      = 'max@maxcorp.com',
            Phone                      = '(11) 98888-7777',
            Title                      = 'CTO',
            LeadSource                 = 'Web',
            Company_Size__c            = '1000+',
            Annual_Revenue_Estimate__c = 9999999
        );
        insert lead;

        lead = [
            SELECT Id, Email, Phone, Title, LeadSource,
                   Company_Size__c, Annual_Revenue_Estimate__c, Lead_Score__c
            FROM Lead WHERE Id = :lead.Id
        ];

        Test.startTest();
        LeadScoringService.scoreLeads(new List<Lead>{ lead });
        Test.stopTest();

        Lead scored = [SELECT Lead_Score__c FROM Lead WHERE Id = :lead.Id];
        System.assert(scored.Lead_Score__c <= 100, 'Score não pode ultrapassar 100');
    }

    @IsTest
    static void testBulkScoring() {
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 50; i++) {
            leads.add(new Lead(
                FirstName  = 'Bulk', LastName = 'Lead' + i,
                Company    = 'BulkCo' + i,
                Email      = 'lead' + i + '@company.com',
                LeadSource = 'Referral'
            ));
        }
        insert leads;

        leads = [
            SELECT Id, Email, Phone, Title, LeadSource,
                   Company_Size__c, Annual_Revenue_Estimate__c, Lead_Score__c
            FROM Lead WHERE LastName LIKE 'Lead%'
        ];

        Test.startTest();
        LeadScoringService.scoreLeads(leads);
        Test.stopTest();

        for (Lead l : [SELECT Lead_Score__c FROM Lead WHERE LastName LIKE 'Lead%']) {
            System.assert(l.Lead_Score__c >= 0, 'Score não pode ser negativo');
            System.assert(l.Lead_Score__c <= 100, 'Score não pode exceder 100');
        }
    }

    @IsTest
    static void testListaVazia() {
        Test.startTest();
        LeadScoringService.scoreLeads(new List<Lead>());
        Test.stopTest();
        System.assert(true, 'Lista vazia não deve causar erro');
    }
}
