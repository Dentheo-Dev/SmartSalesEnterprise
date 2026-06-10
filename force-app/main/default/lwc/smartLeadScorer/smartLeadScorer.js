import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getLeadDetails from '@salesforce/apex/LeadScorerController.getLeadDetails';
import scoreLead from '@salesforce/apex/LeadScorerController.scoreLead';

export default class SmartLeadScorer extends LightningElement {
    @api recordId;
    @track isSaving = false;
    @track errorMessage;

    _wiredLeadResult;
    lead;

    @wire(getLeadDetails, { leadId: '$recordId' })
    wiredLead(result) {
        this._wiredLeadResult = result;
        if (result.data) {
            this.lead = result.data;
            this.errorMessage = null;
        } else if (result.error) {
            this.lead = null;
            this.errorMessage = result.error.body?.message ?? 'Erro ao carregar dados do lead.';
        }
    }

    get isLoading() {
        return !this.lead && !this.errorMessage;
    }

    get hasError() {
        return !!this.errorMessage;
    }

    get scoreDisplay() {
        return this.lead?.Lead_Score__c ?? 0;
    }

    get scoreLabel() {
        const score = this.lead?.Lead_Score__c ?? 0;
        if (score >= 70) return 'Quente';
        if (score >= 40) return 'Morno';
        return 'Frio';
    }

    get scoreCircleClass() {
        const score = this.lead?.Lead_Score__c ?? 0;
        if (score >= 70) return 'score-circle score-hot';
        if (score >= 40) return 'score-circle score-warm';
        return 'score-circle score-cold';
    }

    get scoreBadgeClass() {
        const score = this.lead?.Lead_Score__c ?? 0;
        if (score >= 70) return 'score-badge badge-hot';
        if (score >= 40) return 'score-badge badge-warm';
        return 'score-badge badge-cold';
    }

    get hasScoreReason() {
        return !!this.lead?.Score_Reason__c;
    }

    async handleScore() {
        this.isSaving = true;
        try {
            await scoreLead({ leadId: this.recordId });
            await refreshApex(this._wiredLeadResult);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Sucesso',
                message: 'Lead pontuado com sucesso!',
                variant: 'success'
            }));
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Erro ao pontuar lead',
                message: error.body?.message ?? 'Ocorreu um erro inesperado.',
                variant: 'error'
            }));
        } finally {
            this.isSaving = false;
        }
    }
}
