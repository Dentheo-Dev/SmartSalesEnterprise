import { LightningElement, wire, track } from 'lwc';
import getExpiringContracts from '@salesforce/apex/ContractRenewalController.getExpiringContracts';

export default class ContractRenewalPanel extends LightningElement {
    @track daysThreshold = '90';
    @track isLoading = true;

    contracts;

    daysOptions = [
        { label: '30 dias', value: '30' },
        { label: '60 dias', value: '60' },
        { label: '90 dias', value: '90' },
    ];

    @wire(getExpiringContracts, { daysThreshold: '$daysThresholdInt' })
    wiredContracts({ data, error }) {
        this.isLoading = false;
        if (data) {
            this.contracts = data.map(c => ({
                ...c,
                accountName:   c.Account__r?.Name ?? '—',
                daysLabel:     `${c.Days_Until_Expiration__c ?? '?'} dias`,
                urgencyClass:  this.urgencyClass(c.Days_Until_Expiration__c),
                valueFormatted: c.Renewal_Value__c
                    ? new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' })
                        .format(c.Renewal_Value__c)
                    : '—'
            }));
        }
    }

    get daysThresholdInt() {
        return parseInt(this.daysThreshold, 10);
    }

    get hasContracts() {
        return this.contracts?.length > 0;
    }

    urgencyClass(days) {
        if (days == null)  return 'urgency-badge urgency-neutral';
        if (days <= 30)    return 'urgency-badge urgency-critical';
        if (days <= 60)    return 'urgency-badge urgency-warning';
        return 'urgency-badge urgency-info';
    }

    handleDaysChange(event) {
        this.isLoading = true;
        this.daysThreshold = event.detail.value;
    }
}
