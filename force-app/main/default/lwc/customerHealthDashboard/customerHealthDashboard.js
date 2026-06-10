import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getHealthRecord from '@salesforce/apex/CustomerHealthController.getHealthRecord';
import recalculate from '@salesforce/apex/CustomerHealthController.recalculate';

export default class CustomerHealthDashboard extends LightningElement {
    @api recordId;
    @track isRecalculating = false;

    _wiredResult;
    health;
    isLoading = true;

    @wire(getHealthRecord, { accountId: '$recordId' })
    wiredHealth(result) {
        this._wiredResult = result;
        this.isLoading = false;
        if (result.data !== undefined) {
            this.health = result.data;
        }
    }

    get noRecord() {
        return !this.isLoading && !this.health;
    }

    get npsDisplay() {
        return this.health?.NPS_Score__c ?? '—';
    }

    get hasAiAnalysis() {
        return !!this.health?.AI_Health_Analysis__c;
    }

    get lastCalculatedFormatted() {
        if (!this.health?.Last_Calculated__c) return '—';
        return new Date(this.health.Last_Calculated__c).toLocaleDateString('pt-BR');
    }

    get healthCircleClass() {
        const score = this.health?.Health_Score__c ?? 0;
        if (score > 80) return 'health-circle health-excellent';
        if (score > 60) return 'health-circle health-good';
        if (score > 30) return 'health-circle health-risk';
        return 'health-circle health-critical';
    }

    get statusBadgeClass() {
        const status = this.health?.Health_Status__c ?? '';
        const map = {
            'Excelente': 'status-excellent',
            'Saudável':  'status-good',
            'Em Risco':  'status-risk',
            'Crítico':   'status-critical'
        };
        return `status-badge ${map[status] ?? 'status-neutral'}`;
    }

    async handleRecalculate() {
        this.isRecalculating = true;
        try {
            await recalculate({ accountId: this.recordId });
            await refreshApex(this._wiredResult);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Saúde Recalculada',
                message: 'Score atualizado com sucesso.',
                variant: 'success'
            }));
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Erro ao recalcular',
                message: error.body?.message ?? 'Ocorreu um erro inesperado.',
                variant: 'error'
            }));
        } finally {
            this.isRecalculating = false;
        }
    }
}
