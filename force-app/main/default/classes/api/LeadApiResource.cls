@RestResource(urlMapping='/smartsales/v1/leads/*')
global with sharing class LeadApiResource {

    @HttpGet
    global static void doGet() {
        RestRequest  req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            String recordId = ApiUtils.extractIdFromUri(req.requestURI);

            if (String.isNotBlank(recordId)) {
                List<Lead> leads = LeadSelector.getInstance().selectById(new Set<Id>{ (Id) recordId });
                if (leads.isEmpty()) {
                    res.statusCode   = 404;
                    res.responseBody = Blob.valueOf(JSON.serialize(
                        ApiResponseWrapper.fail('Lead não encontrado')
                    ));
                    return;
                }
                res.statusCode   = 200;
                res.responseBody = Blob.valueOf(JSON.serialize(ApiResponseWrapper.ok(leads[0])));
            } else {
                String status   = req.params != null ? req.params.get('status')   : null;
                String minScore = req.params != null ? req.params.get('minScore') : null;

                List<Lead> leads;
                if (String.isNotBlank(status)) {
                    leads = LeadSelector.getInstance().selectByStatus(status);
                } else if (String.isNotBlank(minScore)) {
                    leads = LeadSelector.getInstance()
                        .selectUnconvertedByMinScore(Integer.valueOf(minScore));
                } else {
                    leads = LeadSelector.getInstance().selectByStatus('Open - Not Contacted');
                }
                res.statusCode   = 200;
                res.responseBody = Blob.valueOf(JSON.serialize(ApiResponseWrapper.ok(leads)));
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
            Lead newLead = (Lead) JSON.deserialize(req.requestBody.toString(), Lead.class);
            insert newLead;
            res.statusCode   = 201;
            res.responseBody = Blob.valueOf(JSON.serialize(ApiResponseWrapper.ok(newLead)));
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

            Lead updated = (Lead) JSON.deserialize(req.requestBody.toString(), Lead.class);
            updated.Id = (Id) recordId;
            update updated;

            List<Lead> refreshed = LeadSelector.getInstance().selectById(new Set<Id>{ updated.Id });
            res.statusCode   = 200;
            res.responseBody = Blob.valueOf(JSON.serialize(ApiResponseWrapper.ok(refreshed[0])));
        } catch (Exception e) {
            res.statusCode   = 400;
            res.responseBody = Blob.valueOf(JSON.serialize(ApiResponseWrapper.fail(e.getMessage())));
        }
    }

    @HttpDelete
    global static void doDelete() {
        RestRequest  req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            String recordId = ApiUtils.extractIdFromUri(req.requestURI);
            if (String.isBlank(recordId)) {
                res.statusCode   = 400;
                res.responseBody = Blob.valueOf(JSON.serialize(
                    ApiResponseWrapper.fail('Id obrigatório no path para DELETE')
                ));
                return;
            }

            delete new Lead(Id = (Id) recordId);
            res.statusCode = 204;
        } catch (Exception e) {
            res.statusCode   = 400;
            res.responseBody = Blob.valueOf(JSON.serialize(ApiResponseWrapper.fail(e.getMessage())));
        }
    }
}
