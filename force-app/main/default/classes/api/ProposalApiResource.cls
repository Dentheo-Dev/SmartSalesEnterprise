@RestResource(urlMapping='/smartsales/v1/proposals/*')
global with sharing class ProposalApiResource {

    @HttpGet
    global static void doGet() {
        RestRequest  req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            String recordId = ApiUtils.extractIdFromUri(req.requestURI);
            if (String.isBlank(recordId)) {
                res.statusCode   = 400;
                res.responseBody = Blob.valueOf(JSON.serialize(
                    ApiResponseWrapper.fail('Id obrigatório: /proposals/{id}')
                ));
                return;
            }

            Product_Proposal__c proposal;
            try {
                proposal = ProductProposalSelector.getInstance().selectById((Id) recordId);
            } catch (System.QueryException qe) {
                res.statusCode   = 404;
                res.responseBody = Blob.valueOf(JSON.serialize(
                    ApiResponseWrapper.fail('Proposta não encontrada')
                ));
                return;
            }

            res.statusCode   = 200;
            res.responseBody = Blob.valueOf(JSON.serialize(ApiResponseWrapper.ok(proposal)));
        } catch (Exception e) {
            res.statusCode   = 500;
            res.responseBody = Blob.valueOf(JSON.serialize(ApiResponseWrapper.fail(e.getMessage())));
        }
    }

    @HttpPost
    global static void doPost() {
        RestRequest  req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            Product_Proposal__c newProposal = (Product_Proposal__c) JSON.deserialize(
                req.requestBody.toString(), Product_Proposal__c.class
            );
            insert newProposal;
            res.statusCode   = 201;
            res.responseBody = Blob.valueOf(JSON.serialize(ApiResponseWrapper.ok(newProposal)));
        } catch (Exception e) {
            res.statusCode   = 400;
            res.responseBody = Blob.valueOf(JSON.serialize(ApiResponseWrapper.fail(e.getMessage())));
        }
    }
}
