// Executa chamadas de IA de forma assíncrona, contornando a restrição de callout em triggers síncronos
public class AIInsightQueueable implements Queueable, Database.AllowsCallouts {

    private final Id     recordId;
    private final String insightType;

    public AIInsightQueueable(Id recordId, String insightType) {
        this.recordId    = recordId;
        this.insightType = insightType;
    }

    public static void enqueue(Id recordId, String insightType) {
        if (System.isFuture() || System.isBatch()) return;
        System.enqueueJob(new AIInsightQueueable(recordId, insightType));
    }

    public void execute(QueueableContext ctx) {
        if (insightType == AIInsightService.TYPE_OPPORTUNITY) {
            AIInsightService.enrichOpportunityNextStep(recordId);
        } else if (insightType == AIInsightService.TYPE_PROPOSAL) {
            AIInsightService.enrichProposalSummary(recordId);
        } else if (insightType == AIInsightService.TYPE_HEALTH) {
            AIInsightService.enrichHealthAnalysis(recordId);
        }
    }
}
