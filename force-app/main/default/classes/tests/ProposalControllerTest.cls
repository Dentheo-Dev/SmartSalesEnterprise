@IsTest
private class ProposalControllerTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Proposal Controller Corp');
        insert acc;

        Opportunity opp = new Opportunity(
            Name      = 'Proposal Test Opp',
            AccountId = acc.Id,
            Amount    = 50000,
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        insert new Product_Proposal__c(
            Name                   = 'PROP-001',
            Opportunity__c         = opp.Id,
            Account__c             = acc.Id,
            Total_Value__c         = 50000,
            Discount_Percentage__c = 10,
            Status__c              = 'Rascunho',
            Valid_Until__c         = Date.today().addDays(30)
        );
    }

    @IsTest
    static void testGetProposalsByOpportunity() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Proposal Test Opp'];

        Test.startTest();
        List<Product_Proposal__c> result = ProposalController.getProposalsByOpportunity(opp.Id);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Deve retornar 1 proposta');
        System.assertEquals('Rascunho', result[0].Status__c, 'Status deve ser Rascunho');
    }

    @IsTest
    static void testGetProposalsListaVazia() {
        Opportunity opp = new Opportunity(
            Name      = 'Opp Sem Proposta',
            AccountId = [SELECT Id FROM Account LIMIT 1].Id,
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        Test.startTest();
        List<Product_Proposal__c> result = ProposalController.getProposalsByOpportunity(opp.Id);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Deve retornar lista vazia');
    }

    @IsTest
    static void testCreateProposal() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Proposal Test Opp'];

        Test.startTest();
        Id proposalId = ProposalController.createProposal(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, proposalId, 'Deve retornar ID da proposta criada');
        Product_Proposal__c created = [SELECT Status__c FROM Product_Proposal__c WHERE Id = :proposalId];
        System.assertEquals('Rascunho', created.Status__c, 'Nova proposta deve ser Rascunho');
    }

    @IsTest
    static void testUpdateStatus() {
        Product_Proposal__c prop = [SELECT Id FROM Product_Proposal__c LIMIT 1];

        Test.startTest();
        ProposalController.updateStatus(prop.Id, 'Aceita');
        Test.stopTest();

        Product_Proposal__c updated = [SELECT Status__c FROM Product_Proposal__c WHERE Id = :prop.Id];
        System.assertEquals('Aceita', updated.Status__c, 'Status deve ser atualizado para Aceita');
    }

    @IsTest
    static void testUpdateStatusRejeitada() {
        Product_Proposal__c prop = [SELECT Id FROM Product_Proposal__c LIMIT 1];

        Test.startTest();
        ProposalController.updateStatus(prop.Id, 'Rejeitada');
        Test.stopTest();

        Product_Proposal__c updated = [SELECT Status__c FROM Product_Proposal__c WHERE Id = :prop.Id];
        System.assertEquals('Rejeitada', updated.Status__c, 'Status deve ser Rejeitada');
    }
}
