import { LightningElement, wire, track } from 'lwc';
import getCommissionSummary from '@salesforce/apex/CommissionController.getCommissionSummary';
import getCommissions from '@salesforce/apex/CommissionController.getCommissions';

const COLUMNS = [
    { label: 'Oportunidade', fieldName: 'opportunityName', type: 'text' },
    { label: 'Valor (R$)', fieldName: 'Commission_Amount__c', type: 'currency',
      typeAttributes: { currencyCode: 'BRL', minimumFractionDigits: 2 } },
    { label: 'Taxa (%)', fieldName: 'Commission_Rate__c', type: 'number',
      typeAttributes: { maximumFractionDigits: 1 } },
    { label: 'Status', fieldName: 'Status__c', type: 'text' },
    { label: 'Período', fieldName: 'Period__c', type: 'text' },
    { label: 'Data Pagamento', fieldName: 'Payment_Date__c', type: 'date-local' },
];

export default class CommissionTracker extends LightningElement {
    @track selectedStatus = '';
    @track selectedPeriod = '';

    summary;
    isSummaryLoading = true;
    commissions;
    isListLoading = true;
    columns = COLUMNS;

    statusOptions = [
        { label: 'Todos', value: '' },
        { label: 'Calculada', value: 'Calculada' },
        { label: 'Pendente', value: 'Pendente' },
        { label: 'Paga', value: 'Paga' },
    ];

    get periodOptions() {
        const today = new Date();
        const options = [{ label: 'Todos', value: '' }];
        for (let i = 0; i < 12; i++) {
            const d = new Date(today.getFullYear(), today.getMonth() - i, 1);
            const value = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
            options.push({ label: value, value });
        }
        return options;
    }

    @wire(getCommissionSummary)
    wiredSummary({ data, error }) {
        this.isSummaryLoading = false;
        if (data) this.summary = data;
    }

    @wire(getCommissions, { status: '$selectedStatus', period: '$selectedPeriod' })
    wiredCommissions({ data, error }) {
        this.isListLoading = false;
        if (data) {
            this.commissions = data.map(c => ({
                ...c,
                opportunityName: c.Opportunity__r?.Name ?? '—'
            }));
        }
    }

    get hasCommissions() {
        return this.commissions?.length > 0;
    }

    get totalGeralFormatted()     { return this.fmt(this.summary?.totalGeral); }
    get totalPagoFormatted()      { return this.fmt(this.summary?.totalPago); }
    get totalPendenteFormatted()  { return this.fmt(this.summary?.totalPendente); }
    get totalCalculadaFormatted() { return this.fmt(this.summary?.totalCalculada); }

    fmt(value) {
        return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' })
            .format(value ?? 0);
    }

    handleStatusChange(event) {
        this.isListLoading = true;
        this.selectedStatus = event.detail.value;
    }

    handlePeriodChange(event) {
        this.isListLoading = true;
        this.selectedPeriod = event.detail.value;
    }
}
