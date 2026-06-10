public with sharing class LeadScoringService {

    private static final Set<String> FREE_EMAIL_DOMAINS = new Set<String>{
        'gmail.com', 'hotmail.com', 'yahoo.com', 'outlook.com',
        'live.com', 'icloud.com', 'bol.com.br', 'uol.com.br'
    };

    private static final Set<String> LARGE_COMPANY_SIZES = new Set<String>{
        '201-1000', '1000+'
    };

    private static final Set<String> SCORING_SOURCES = new Set<String>{
        'Web', 'Referral'
    };

    private static final Set<String> EXECUTIVE_TITLES = new Set<String>{
        'CEO', 'CTO', 'Director', 'VP'
    };

    /**
     * Calcula score de qualificação (0-100) para cada Lead.
     * Preenche Lead_Score__c e Score_Reason__c.
     */
    public static void scoreLeads(List<Lead> leads) {
        if (leads == null || leads.isEmpty()) {
            return;
        }

        List<Lead> toUpdate = new List<Lead>();

        for (Lead lead : leads) {
            Integer      score   = 0;
            List<String> reasons = new List<String>();

            // Email corporativo (não é domínio gratuito)
            if (String.isNotBlank(lead.Email)) {
                String domain = lead.Email.substringAfterLast('@').toLowerCase();
                if (!FREE_EMAIL_DOMAINS.contains(domain)) {
                    score += 20;
                    reasons.add('+20 email corporativo');
                }
            }

            // Porte da empresa grande
            if (String.isNotBlank(lead.Company_Size__c)
                    && LARGE_COMPANY_SIZES.contains(lead.Company_Size__c)) {
                score += 25;
                reasons.add('+25 empresa grande (' + lead.Company_Size__c + ')');
            }

            // Receita anual acima de R$1M
            if (lead.Annual_Revenue_Estimate__c != null
                    && lead.Annual_Revenue_Estimate__c > 1000000) {
                score += 20;
                reasons.add('+20 receita > R$1M');
            }

            // Telefone preenchido
            if (String.isNotBlank(lead.Phone)) {
                score += 10;
                reasons.add('+10 telefone preenchido');
            }

            // Origem qualificada
            if (String.isNotBlank(lead.LeadSource)
                    && SCORING_SOURCES.contains(lead.LeadSource)) {
                score += 15;
                reasons.add('+15 origem ' + lead.LeadSource);
            }

            // Cargo executivo
            if (String.isNotBlank(lead.Title)) {
                for (String execTitle : EXECUTIVE_TITLES) {
                    if (lead.Title.containsIgnoreCase(execTitle)) {
                        score += 10;
                        reasons.add('+10 cargo executivo');
                        break;
                    }
                }
            }

            toUpdate.add(new Lead(
                Id              = lead.Id,
                Lead_Score__c   = Math.min(score, 100),
                Score_Reason__c = String.join(reasons, ' | ')
            ));
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
            publishScoredEvents(leads, toUpdate);
        }
    }

    private static void publishScoredEvents(
        List<Lead> originalLeads, List<Lead> updatedLeads
    ) {
        Map<Id, Lead> updatedById = new Map<Id, Lead>();
        for (Lead l : updatedLeads) {
            updatedById.put(l.Id, l);
        }

        List<SObject> events = new List<SObject>();
        for (Lead original : originalLeads) {
            Lead updated = updatedById.get(original.Id);
            if (updated == null) continue;

            Decimal previousScore = original.Lead_Score__c != null ? original.Lead_Score__c : 0;
            events.add(new Lead_Scored__e(
                Lead_Id__c        = String.valueOf(original.Id),
                Score__c          = updated.Lead_Score__c,
                Previous_Score__c = previousScore,
                Score_Reason__c   = updated.Score_Reason__c
            ));
        }

        PlatformEventService.publishAll(events);
    }
}
