@RestResource(urlMapping='/smartsales/v1/opportunities/*')
global with sharing class OpportunityApiResource {

    @HttpGet
    global static void doGet() {
        RestRequest  req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            String recordId = ApiUtils.extractIdFromUri(req.requestURI);

            if (String.isNotBlank(recordId)) {
                Opportunity opp = OpportunitySelector.getInstance().selectSingleById((Id) recordId);
                if (opp == null) {
                    res.statusCode   = 404;
                    res.responseBody = Blob.valueOf(JSON.serialize(
                        ApiResponseWrapper.fail('Opportunity não encontrada')
                    ));
                    return;
                }
                res.statusCode   = 200;
                res.responseBody = Blob.valueOf(JSON.serialize(ApiResponseWrapper.ok(opp)));
            } else {
                String accountId = req.params != null ? req.params.get('accountId') : null;
                List<Opportunity> opps;
                if (String.isNotBlank(accountId)) {
                    opps = OpportunitySelector.getInstance()
                        .selectClosedWonByAccountIds(new Set<Id>{ (Id) accountId });
                } else {
                    opps = new List<Opportunity>();
                }
                res.statusCode   = 200;
                res.responseBody = Blob.valueOf(JSON.serialize(ApiResponseWrapper.ok(opps)));
            }
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
            Opportunity newOpp = (Opportunity) JSON.deserialize(
                req.requestBody.toString(), Opportunity.class
            );
            insert newOpp;
            res.statusCode   = 201;
            res.responseBody = Blob.valueOf(JSON.serialize(ApiResponseWrapper.ok(newOpp)));
        } catch (Exception e) {
            res.statusCode   = 400;
            res.responseBody = Blob.valueOf(JSON.serialize(ApiResponseWrapper.fail(e.getMessage())));
        }
    }

    @HttpPatch
    global static void doPatch() {
        RestRequest  req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            String recordId = ApiUtils.extractIdFromUri(req.requestURI);
            if (String.isBlank(recordId)) {
                res.statusCode   = 400;
                res.responseBody = Blob.valueOf(JSON.serialize(
                    ApiResponseWrapper.fail('Id obrigatório no path para PATCH')
                ));
                return;
            }

            Opportunity updated = (Opportunity) JSON.deserialize(
                req.requestBody.toString(), Opportunity.class
            );
            updated.Id = (Id) recordId;
            update updated;

            Opportunity refreshed = OpportunitySelector.getInstance().selectSingleById(updated.Id);
            res.statusCode   = 200;
            res.responseBody = Blob.valueOf(JSON.serialize(ApiResponseWrapper.ok(refreshed)));
        } catch (Exception e) {
            res.statusCode   = 400;
            res.responseBody = Blob.valueOf(JSON.serialize(ApiResponseWrapper.fail(e.getMessage())));
        }
    }
}
