@IsTest
private class ProposalServiceTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Proposal Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name      = 'Test Opportunity',
            AccountId = acc.Id,
            Amount    = 50000,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;
    }

    @IsTest
    static void testCreateProposalCriaRegistro() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity'];

        Test.startTest();
        Id proposalId = ProposalService.createProposal(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, proposalId, 'Proposta deve ser criada');

        Product_Proposal__c proposal = [
            SELECT Status__c, Opportunity__c, Account__c,
                   Total_Value__c, Discount_Percentage__c, Valid_Until__c
            FROM Product_Proposal__c
            WHERE Id = :proposalId
        ];
        System.assertEquals('Rascunho',                  proposal.Status__c,             'Status inicial deve ser Rascunho');
        System.assertEquals(opp.Id,                      proposal.Opportunity__c,         'Opportunity deve estar vinculada');
        System.assertEquals(50000,                       proposal.Total_Value__c,         'Valor total deve vir da Opportunity');
        System.assertEquals(0,                           proposal.Discount_Percentage__c, 'Desconto inicial deve ser 0');
        System.assertEquals(Date.today().addDays(30),   proposal.Valid_Until__c,         'Validade padrão: 30 dias');
    }

    @IsTest
    static void testSendProposalAlteraStatusEPreencheData() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity'];
        Id proposalId   = ProposalService.createProposal(opp.Id);

        Test.startTest();
        ProposalService.sendProposal(proposalId);
        Test.stopTest();

        Product_Proposal__c proposal = [
            SELECT Status__c, Sent_Date__c
            FROM Product_Proposal__c WHERE Id = :proposalId
        ];
        System.assertEquals('Enviada', proposal.Status__c,   'Status deve ser Enviada');
        System.assertNotEquals(null,   proposal.Sent_Date__c, 'Sent_Date__c deve ser preenchida');
    }

    @IsTest
    static void testExpireProposalsVencidas() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE Name = 'Test Opportunity'];

        // Proposta com validade vencida
        Product_Proposal__c expired = new Product_Proposal__c(
            Name           = 'PROP-VENC-001',
            Opportunity__c = opp.Id,
            Account__c     = opp.AccountId,
            Status__c      = 'Enviada',
            Valid_Until__c = Date.today().addDays(-5),
            Total_Value__c = 50000
        );
        insert expired;

        // Proposta ainda válida — não deve expirar
        Product_Proposal__c valid = new Product_Proposal__c(
            Name           = 'PROP-VALID-001',
            Opportunity__c = opp.Id,
            Account__c     = opp.AccountId,
            Status__c      = 'Enviada',
            Valid_Until__c = Date.today().addDays(10),
            Total_Value__c = 50000
        );
        insert valid;

        Test.startTest();
        ProposalService.expireProposals();
        Test.stopTest();

        System.assertEquals('Expirada', [SELECT Status__c FROM Product_Proposal__c WHERE Id = :expired.Id].Status__c,
            'Proposta vencida deve ter status Expirada');
        System.assertEquals('Enviada', [SELECT Status__c FROM Product_Proposal__c WHERE Id = :valid.Id].Status__c,
            'Proposta válida não deve ser expirada');
    }

    @IsTest
    static void testExpireProposalsIgnoraRascunho() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE Name = 'Test Opportunity'];

        // Rascunho vencido — não deve ser expirado (apenas Enviada é expirada)
        Product_Proposal__c draft = new Product_Proposal__c(
            Name           = 'PROP-DRAFT-001',
            Opportunity__c = opp.Id,
            Account__c     = opp.AccountId,
            Status__c      = 'Rascunho',
            Valid_Until__c = Date.today().addDays(-1),
            Total_Value__c = 10000
        );
        insert draft;

        Test.startTest();
        ProposalService.expireProposals();
        Test.stopTest();

        System.assertEquals('Rascunho', [SELECT Status__c FROM Product_Proposal__c WHERE Id = :draft.Id].Status__c,
            'Rascunho não deve ser expirado');
    }

    @IsTest
    static void testValidateDiscountDescontoValido() {
        Product_Proposal__c proposal = new Product_Proposal__c(
            Discount_Percentage__c = 30
        );

        Test.startTest();
        try {
            ProposalService.validateDiscount(proposal);
            System.assert(true, 'Desconto de 30% deve ser aceito');
        } catch (ProposalService.ProposalException e) {
            System.assert(false, 'Não deveria lançar exceção para desconto válido: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void testValidateDiscountDescontoInvalido() {
        Product_Proposal__c proposal = new Product_Proposal__c(
            Discount_Percentage__c = 55
        );

        Test.startTest();
        try {
            ProposalService.validateDiscount(proposal);
            System.assert(false, 'Deveria lançar ProposalException para desconto > 50%');
        } catch (ProposalService.ProposalException e) {
            System.assert(e.getMessage().contains('50%'), 'Mensagem deve mencionar o limite de 50%');
        }
        Test.stopTest();
    }

    @IsTest
    static void testSendProposalComDescontoInvalidoLancaExcecao() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE Name = 'Test Opportunity'];

        Product_Proposal__c proposal = new Product_Proposal__c(
            Name                   = 'PROP-HIGH-DISC',
            Opportunity__c         = opp.Id,
            Account__c             = opp.AccountId,
            Status__c              = 'Rascunho',
            Total_Value__c         = 50000,
            Discount_Percentage__c = 60,
            Valid_Until__c         = Date.today().addDays(30)
        );
        insert proposal;

        Test.startTest();
        try {
            ProposalService.sendProposal(proposal.Id);
            System.assert(false, 'Deveria lançar exceção para desconto de 60%');
        } catch (ProposalService.ProposalException e) {
            System.assert(e.getMessage().contains('50%'), 'Exceção deve mencionar limite de 50%');
        }
        Test.stopTest();

        // Status não deve ter mudado
        System.assertEquals('Rascunho',
            [SELECT Status__c FROM Product_Proposal__c WHERE Id = :proposal.Id].Status__c,
            'Status deve permanecer Rascunho após falha na validação'
        );
    }
}
