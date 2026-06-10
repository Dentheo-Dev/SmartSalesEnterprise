public with sharing class ProposalService {

    /**
     * Cria uma proposta no status Rascunho a partir de uma Opportunity.
     * @param opportunityId ID da Opportunity base
     * @return ID da proposta criada
     */
    public static Id createProposal(Id opportunityId) {
        Opportunity opp = [
            SELECT Id, AccountId, Amount, CloseDate
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];

        String proposalNumber = 'PROP-' + String.valueOf(Datetime.now().getTime()).right(6);

        Product_Proposal__c proposal = new Product_Proposal__c(
            Name                  = proposalNumber,
            Opportunity__c        = opportunityId,
            Account__c            = opp.AccountId,
            Total_Value__c        = opp.Amount,
            Discount_Percentage__c = 0,
            Status__c             = 'Rascunho',
            Valid_Until__c        = Date.today().addDays(30)
        );

        insert proposal;
        return proposal.Id;
    }

    /**
     * Envia a proposta: muda status para Enviada, registra data e notifica por e-mail.
     * @param proposalId ID da proposta a enviar
     */
    public static void sendProposal(Id proposalId) {
        Product_Proposal__c proposal = [
            SELECT Id, Status__c, Sent_Date__c, Discount_Percentage__c,
                   Total_Value__c, Final_Value__c,
                   Account__r.Name,
                   Opportunity__r.Owner.Email, Opportunity__r.Owner.Name
            FROM Product_Proposal__c
            WHERE Id = :proposalId
            LIMIT 1
        ];

        validateDiscount(proposal);

        proposal.Status__c    = 'Enviada';
        proposal.Sent_Date__c = Datetime.now();
        update proposal;

        notifyProposalSent(proposal);
    }

    /**
     * Expira propostas com Valid_Until__c vencida e status = Enviada.
     * Chamado pelo ProposalExpirationBatch (Passo 8).
     */
    public static void expireProposals() {
        List<Product_Proposal__c> expired = [
            SELECT Id, Status__c
            FROM Product_Proposal__c
            WHERE Status__c = 'Enviada' AND Valid_Until__c < TODAY
        ];

        for (Product_Proposal__c p : expired) {
            p.Status__c = 'Expirada';
        }

        if (!expired.isEmpty()) {
            update expired;
        }
    }

    /**
     * Valida que o desconto não ultrapassa 50%.
     * Acima desse limite é necessário aprovação especial.
     * @param proposal Proposta a validar
     */
    public static void validateDiscount(Product_Proposal__c proposal) {
        if (proposal.Discount_Percentage__c != null
                && proposal.Discount_Percentage__c > 50) {
            throw new ProposalException(
                'Desconto acima de 50% requer aprovação especial. '
                + 'Desconto solicitado: ' + proposal.Discount_Percentage__c + '%'
            );
        }
    }

    private static void notifyProposalSent(Product_Proposal__c proposal) {
        try {
            String ownerEmail = proposal.Opportunity__r?.Owner?.Email;
            if (String.isBlank(ownerEmail)) {
                return;
            }

            String accountName = proposal.Account__r != null
                ? proposal.Account__r.Name : 'Cliente';

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{ ownerEmail });
            email.setSubject('Proposta Enviada — ' + accountName);
            email.setPlainTextBody(
                'A proposta para o cliente ' + accountName + ' foi enviada com sucesso.\n\n'
                + 'Valor final: R$ ' + proposal.Final_Value__c + '\n'
                + 'Acesse o Salesforce para acompanhar o andamento.'
            );

            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
        } catch (Exception e) {
            // Falha de e-mail não deve bloquear o envio da proposta
            System.debug(LoggingLevel.WARN, 'Erro ao enviar notificação da proposta: ' + e.getMessage());
        }
    }

    public class ProposalException extends Exception {}
}
