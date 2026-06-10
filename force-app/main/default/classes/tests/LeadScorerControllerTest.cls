@IsTest
private class LeadScorerControllerTest {

    @TestSetup
    static void setup() {
        insert new Lead(
            FirstName  = 'Test',
            LastName   = 'Lead',
            Company    = 'TestCo',
            Email      = 'test@testco.com.br',
            Phone      = '(11) 99999-0000',
            LeadSource = 'Web'
        );
    }

    @IsTest
    static void testGetLeadDetails() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];

        Test.startTest();
        Lead result = LeadScorerController.getLeadDetails(lead.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Deve retornar o lead');
        System.assertEquals(lead.Id, result.Id, 'ID deve corresponder');
    }

    @IsTest
    static void testGetLeadDetailsIdInexistente() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        // Deleta para simular ID inexistente mas manter ID válido no formato
        delete lead;

        Test.startTest();
        Lead result = LeadScorerController.getLeadDetails(lead.Id);
        Test.stopTest();

        System.assertEquals(null, result, 'Deve retornar null para ID inexistente');
    }

    @IsTest
    static void testScoreLead() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];

        Test.startTest();
        LeadScorerController.scoreLead(lead.Id);
        Test.stopTest();

        Lead scored = [SELECT Lead_Score__c FROM Lead WHERE Id = :lead.Id];
        System.assertNotEquals(null, scored.Lead_Score__c, 'Score deve ser calculado');
    }

    @IsTest
    static void testScoreLeadInexistente() {
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        delete lead;

        Test.startTest();
        // Não deve lançar exceção para lead inexistente
        LeadScorerController.scoreLead(lead.Id);
        Test.stopTest();

        System.assert(true, 'Não deve lançar exceção para lead inexistente');
    }
}
