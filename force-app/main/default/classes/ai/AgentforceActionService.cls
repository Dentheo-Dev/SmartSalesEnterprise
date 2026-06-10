// Ação invocável para Agentforce e Flows — permite que agentes de IA chamem geração de insights
public with sharing class AgentforceActionService {

    public class InsightRequest {
        @InvocableVariable(label='Record ID' required=true)
        public Id recordId;

        @InvocableVariable(label='Tipo de Insight' description='OPPORTUNITY, PROPOSAL ou HEALTH' required=true)
        public String insightType;
    }

    public class InsightResult {
        @InvocableVariable(label='Texto do Insight')
        public String insightText;

        @InvocableVariable(label='Sucesso')
        public Boolean success;

        @InvocableVariable(label='Mensagem de Erro')
        public String errorMessage;
    }

    @InvocableMethod(
        label='Gerar Insight de IA'
        description='Chama a OpenAI para gerar insights contextuais para Opportunities, Propostas e Customer Health'
        category='SmartSales AI'
    )
    public static List<InsightResult> generateInsight(List<InsightRequest> requests) {
        List<InsightResult> results = new List<InsightResult>();

        for (InsightRequest req : requests) {
            InsightResult result = new InsightResult();
            try {
                if (req.insightType == AIInsightService.TYPE_OPPORTUNITY) {
                    AIInsightService.enrichOpportunityNextStep(req.recordId);
                } else if (req.insightType == AIInsightService.TYPE_PROPOSAL) {
                    AIInsightService.enrichProposalSummary(req.recordId);
                } else if (req.insightType == AIInsightService.TYPE_HEALTH) {
                    AIInsightService.enrichHealthAnalysis(req.recordId);
                } else {
                    throw new IllegalArgumentException('Tipo de insight inválido: ' + req.insightType);
                }
                result.success     = true;
                result.insightText = 'Insight gerado com sucesso para ' + req.recordId;
            } catch (Exception e) {
                result.success      = false;
                result.errorMessage = e.getMessage();
            }
            results.add(result);
        }

        return results;
    }
}
