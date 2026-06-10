public with sharing class IntegrationLogService {

    public static Integration_Log__c buildLog(
        String serviceName,
        String requestBody,
        String responseBody,
        Integer statusCode,
        Boolean success,
        Long durationMs,
        String relatedRecordId,
        String errorMessage
    ) {
        return new Integration_Log__c(
            Service_Name__c      = serviceName,
            Request_Body__c      = truncate(requestBody, 32768),
            Response_Body__c     = truncate(responseBody, 32768),
            Status_Code__c       = statusCode,
            Success__c           = success,
            Duration_Ms__c       = durationMs,
            Related_Record_Id__c = relatedRecordId,
            Created_At__c        = Datetime.now(),
            Error_Message__c     = truncate(errorMessage, 32768)
        );
    }

    // Insere logs de forma best-effort — falha silenciosa para não abortar o fluxo principal
    public static void save(List<Integration_Log__c> logs) {
        if (logs == null || logs.isEmpty()) return;
        Database.insert(logs, false);
    }

    private static String truncate(String val, Integer maxLen) {
        if (val == null) return null;
        return val.length() > maxLen ? val.substring(0, maxLen) : val;
    }
}
