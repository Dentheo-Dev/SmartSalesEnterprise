public with sharing class CommissionController {

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getCommissionSummary() {
        Id userId = UserInfo.getUserId();
        Decimal totalPago = 0, totalPendente = 0, totalCalculada = 0;
        for (AggregateResult ar : [
            SELECT Status__c, SUM(Commission_Amount__c) total
            FROM Commission__c
            WHERE Sales_Rep__c = :userId
            GROUP BY Status__c
        ]) {
            String s = (String) ar.get('Status__c');
            Decimal t = ar.get('total') != null ? (Decimal) ar.get('total') : 0;
            if      (s == 'Paga')      totalPago      += t;
            else if (s == 'Pendente')  totalPendente  += t;
            else                       totalCalculada += t;
        }
        return new Map<String, Object>{
            'totalPago'      => totalPago,
            'totalPendente'  => totalPendente,
            'totalCalculada' => totalCalculada,
            'totalGeral'     => totalPago + totalPendente + totalCalculada
        };
    }

    @AuraEnabled(cacheable=true)
    public static List<Commission__c> getCommissions(String status, String period) {
        Id userId = UserInfo.getUserId();
        Map<String, Object> binds = new Map<String, Object>{ 'userId' => userId };

        String q = 'SELECT Id, Name, Commission_Amount__c, Commission_Rate__c,'
                 + ' Status__c, Period__c, Opportunity__r.Name, Payment_Date__c'
                 + ' FROM Commission__c'
                 + ' WHERE Sales_Rep__c = :userId';

        if (String.isNotBlank(status)) {
            q += ' AND Status__c = :status';
            binds.put('status', status);
        }
        if (String.isNotBlank(period)) {
            q += ' AND Period__c = :period';
            binds.put('period', period);
        }
        q += ' ORDER BY CreatedDate DESC LIMIT 200';

        return Database.queryWithBinds(q, binds, AccessLevel.SYSTEM_MODE);
    }
}
