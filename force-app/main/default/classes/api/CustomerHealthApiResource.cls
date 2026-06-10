@RestResource(urlMapping='/smartsales/v1/health/*')
global with sharing class CustomerHealthApiResource {

    @HttpGet
    global static void doGet() {
        RestRequest  req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            String accountId = ApiUtils.extractIdFromUri(req.requestURI);
            if (String.isBlank(accountId)) {
                res.statusCode   = 400;
                res.responseBody = Blob.valueOf(JSON.serialize(
                    ApiResponseWrapper.fail('AccountId obrigatório: /health/{accountId}')
                ));
                return;
            }

            Map<Id, Customer_Health__c> healthMap = CustomerHealthSelector.getInstance()
                .selectLatestByAccountIds(new Set<Id>{ (Id) accountId });

            if (healthMap.isEmpty()) {
                res.statusCode   = 404;
                res.responseBody = Blob.valueOf(JSON.serialize(
                    ApiResponseWrapper.fail('Saúde do cliente não encontrada para este Account')
                ));
                return;
            }

            res.statusCode   = 200;
            res.responseBody = Blob.valueOf(JSON.serialize(
                ApiResponseWrapper.ok(healthMap.get((Id) accountId))
            ));
        } catch (Exception e) {
            res.statusCode   = 500;
            res.responseBody = Blob.valueOf(JSON.serialize(ApiResponseWrapper.fail(e.getMessage())));
        }
    }
}
