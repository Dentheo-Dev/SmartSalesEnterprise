public class LeadTriggerHandler extends TriggerHandler {

    private List<Lead> newList;
    private List<Lead> oldList;
    private Map<Id, Lead> newMap;
    private Map<Id, Lead> oldMap;

    public LeadTriggerHandler() {
        this.newList = (List<Lead>) Trigger.new;
        this.oldList = (List<Lead>) Trigger.old;
        this.newMap  = (Map<Id, Lead>) Trigger.newMap;
        this.oldMap  = (Map<Id, Lead>) Trigger.oldMap;
    }

    override protected void beforeInsert() {
        normalizePhones(newList);
    }

    override protected void afterInsert() {
        LeadScoringService.scoreLeads(newList);
    }

    override protected void afterUpdate() {
        List<Lead> emailChanged = new List<Lead>();

        for (Lead lead : newList) {
            Lead old = oldMap.get(lead.Id);
            if (lead.Email != old.Email) {
                emailChanged.add(lead);
            }
        }

        if (!emailChanged.isEmpty()) {
            LeadScoringService.scoreLeads(emailChanged);
        }
    }

    // Normaliza telefone para formato brasileiro (XX) XXXXX-XXXX
    private static void normalizePhones(List<Lead> leads) {
        for (Lead lead : leads) {
            if (String.isBlank(lead.Phone)) {
                continue;
            }

            String digits = lead.Phone.replaceAll('[^0-9]', '');

            // Remove o 55 do código do país se presente
            if (digits.length() == 13 && digits.startsWith('55')) {
                digits = digits.substring(2);
            }

            if (digits.length() == 11) {
                // Celular com 9 dígito: (XX) 9XXXX-XXXX
                lead.Phone = '(' + digits.substring(0, 2) + ') '
                           + digits.substring(2, 7) + '-'
                           + digits.substring(7);
            } else if (digits.length() == 10) {
                // Fixo: (XX) XXXX-XXXX
                lead.Phone = '(' + digits.substring(0, 2) + ') '
                           + digits.substring(2, 6) + '-'
                           + digits.substring(6);
            }
            // Outros formatos são mantidos como estão
        }
    }
}
