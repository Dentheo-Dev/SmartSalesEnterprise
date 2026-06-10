public with sharing class LeadScorerController {

    @AuraEnabled(cacheable=true)
    public static Lead getLeadDetails(Id leadId) {
        List<Lead> leads = LeadSelector.getInstance().selectById(new Set<Id>{ leadId });
        return leads.isEmpty() ? null : leads[0];
    }

    @AuraEnabled
    public static void scoreLead(Id leadId) {
        List<Lead> leads = LeadSelector.getInstance().selectById(new Set<Id>{ leadId });
        if (!leads.isEmpty()) {
            LeadScoringService.scoreLeads(leads);
        }
    }
}
