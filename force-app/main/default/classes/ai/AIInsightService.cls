public with sharing class AIInsightService {

    public static final String TYPE_OPPORTUNITY = 'OPPORTUNITY';
    public static final String TYPE_PROPOSAL    = 'PROPOSAL';
    public static final String TYPE_HEALTH      = 'HEALTH';

    private static final String SYS_VENDAS =
        'Você é um especialista em vendas B2B de software enterprise. '
        + 'Responda em português. Seja direto e prático. Máximo de 3 frases.';

    private static final String SYS_PROPOSTA =
        'Você é um especialista em propostas comerciais B2B. '
        + 'Responda em português. Gere um resumo executivo conciso. Máximo de 4 frases.';

    private static final String SYS_CS =
        'Você é um especialista em Customer Success B2B. '
        + 'Responda em português. Identifique riscos e oportunidades de retenção. Máximo de 4 frases.';

    public static void enrichOpportunityNextStep(Id opportunityId) {
        Opportunity opp = [
            SELECT Id, Name, Amount, StageName, Description, CloseDate,
                   Account.Name, Account.Industry, Account.AnnualRevenue,
                   Owner.Name
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];

        String userPrompt =
            'Oportunidade: '   + opp.Name
            + '\nEmpresa: '    + nvl(opp.Account?.Name)
            + '\nSegmento: '   + nvl(opp.Account?.Industry)
            + '\nValor: R$ '   + fmtDec(opp.Amount)
            + '\nStage: '      + opp.StageName
            + '\nFechamento: ' + String.valueOf(opp.CloseDate)
            + '\n\nSugira os próximos passos para maximizar o sucesso desta venda.';

        String insight = OpenAICalloutService.generateChatCompletion(SYS_VENDAS, userPrompt);
        if (String.isNotBlank(insight)) {
            update new Opportunity(Id = opportunityId, AI_Next_Step__c = insight);
        }
    }

    public static void enrichProposalSummary(Id proposalId) {
        Product_Proposal__c p = [
            SELECT Id, Name, Total_Value__c, Discount_Percentage__c, Final_Value__c,
                   Status__c, Valid_Until__c,
                   Opportunity__r.Name, Opportunity__r.StageName,
                   Account__r.Name, Account__r.Industry
            FROM Product_Proposal__c
            WHERE Id = :proposalId
            LIMIT 1
        ];

        String userPrompt =
            'Proposta: '           + p.Name
            + '\nCliente: '        + nvl(p.Account__r?.Name)
            + '\nSegmento: '       + nvl(p.Account__r?.Industry)
            + '\nOportunidade: '   + nvl(p.Opportunity__r?.Name)
            + '\nValor Total: R$ ' + fmtDec(p.Total_Value__c)
            + '\nDesconto: '       + (p.Discount_Percentage__c != null ? p.Discount_Percentage__c + '%' : '0%')
            + '\nValor Final: R$ ' + fmtDec(p.Final_Value__c)
            + '\nStatus: '         + p.Status__c
            + '\nVálida até: '     + String.valueOf(p.Valid_Until__c)
            + '\n\nGere um resumo executivo desta proposta para o cliente.';

        String insight = OpenAICalloutService.generateChatCompletion(SYS_PROPOSTA, userPrompt);
        if (String.isNotBlank(insight)) {
            update new Product_Proposal__c(Id = proposalId, AI_Summary__c = insight);
        }
    }

    public static void enrichHealthAnalysis(Id healthId) {
        Customer_Health__c h = [
            SELECT Id, Health_Score__c, Health_Status__c,
                   Open_Cases__c, NPS_Score__c, Payment_Delays__c, Last_Purchase_Days__c,
                   Account__r.Name, Account__r.Industry
            FROM Customer_Health__c
            WHERE Id = :healthId
            LIMIT 1
        ];

        String userPrompt =
            'Cliente: '             + nvl(h.Account__r?.Name)
            + '\nSegmento: '        + nvl(h.Account__r?.Industry)
            + '\nHealth Score: '    + h.Health_Score__c
            + '\nStatus: '          + h.Health_Status__c
            + '\nCasos Abertos: '   + h.Open_Cases__c
            + '\nNPS: '             + h.NPS_Score__c
            + '\nAtrasos Pgto: '    + h.Payment_Delays__c
            + '\nDias s/ compra: '  + h.Last_Purchase_Days__c
            + '\n\nAnalise o health deste cliente e recomende ações para reduzir risco de churn.';

        String insight = OpenAICalloutService.generateChatCompletion(SYS_CS, userPrompt);
        if (String.isNotBlank(insight)) {
            update new Customer_Health__c(Id = healthId, AI_Health_Analysis__c = insight);
        }
    }

    private static String nvl(String val) {
        return String.isNotBlank(val) ? val : 'N/A';
    }

    private static String fmtDec(Decimal val) {
        return val != null ? val.setScale(2).format() : 'N/A';
    }
}
