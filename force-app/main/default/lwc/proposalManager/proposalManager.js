import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getProposalsByOpportunity from '@salesforce/apex/ProposalController.getProposalsByOpportunity';
import createProposal from '@salesforce/apex/ProposalController.createProposal';
import sendProposal from '@salesforce/apex/ProposalController.sendProposal';
import updateStatus from '@salesforce/apex/ProposalController.updateStatus';

const COLUMNS = [
    { label: 'Nome', fieldName: 'Name', type: 'text' },
    { label: 'Status', fieldName: 'Status__c', type: 'text' },
    { label: 'Valor Total', fieldName: 'Total_Value__c', type: 'currency',
      typeAttributes: { currencyCode: 'BRL', minimumFractionDigits: 2 } },
    { label: 'Desconto (%)', fieldName: 'Discount_Percentage__c', type: 'number',
      typeAttributes: { maximumFractionDigits: 1 } },
    { label: 'Valor Final', fieldName: 'Final_Value__c', type: 'currency',
      typeAttributes: { currencyCode: 'BRL', minimumFractionDigits: 2 } },
    { label: 'Válido Até', fieldName: 'Valid_Until__c', type: 'date-local' },
];

const ROW_ACTIONS = [
    { label: 'Enviar Proposta', name: 'send' },
    { label: 'Marcar como Aceita', name: 'accept' },
    { label: 'Marcar como Rejeitada', name: 'reject' },
];

export default class ProposalManager extends LightningElement {
    @api recordId;
    @track isCreating = false;

    _wiredResult;
    proposals;
    isLoading = true;
    columns = COLUMNS;
    rowActions = ROW_ACTIONS;

    @wire(getProposalsByOpportunity, { opportunityId: '$recordId' })
    wiredProposals(result) {
        this._wiredResult = result;
        this.isLoading = false;
        if (result.data) {
            this.proposals = result.data;
        }
    }

    get hasProposals() {
        return this.proposals?.length > 0;
    }

    async handleCreateProposal() {
        this.isCreating = true;
        try {
            await createProposal({ opportunityId: this.recordId });
            await refreshApex(this._wiredResult);
            this.showToast('Proposta Criada', 'Nova proposta gerada no status Rascunho.', 'success');
        } catch (error) {
            this.showToast('Erro ao criar', error.body?.message ?? 'Ocorreu um erro inesperado.', 'error');
        } finally {
            this.isCreating = false;
        }
    }

    async handleRowAction(event) {
        const { action, row } = event.detail;
        try {
            if (action.name === 'send') {
                await sendProposal({ proposalId: row.Id });
                this.showToast('Proposta Enviada', 'Status atualizado para Enviada.', 'success');
            } else if (action.name === 'accept') {
                await updateStatus({ proposalId: row.Id, status: 'Aceita' });
                this.showToast('Proposta Aceita', 'Status atualizado para Aceita.', 'success');
            } else if (action.name === 'reject') {
                await updateStatus({ proposalId: row.Id, status: 'Rejeitada' });
                this.showToast('Proposta Rejeitada', 'Status atualizado para Rejeitada.', 'warning');
            }
            await refreshApex(this._wiredResult);
        } catch (error) {
            this.showToast('Erro', error.body?.message ?? 'Ocorreu um erro.', 'error');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
