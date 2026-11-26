@RestResource(urlMapping='/api/v1/autoprotect/policies/*')
global with sharing class PolicyWebhookService {
    @HttpPost
    global static void syncExternalPolicy() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String reqBody = req.requestBody != null ? req.requestBody.toString() : '';

        try {
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(reqBody);
            Account acc = new Account(
                Name = (String) data.get('customerName'),
                Email__c = (String) data.get('email'),
                Customer_Type__c = 'Individual',
                PAN__c = (String) data.get('pan')
            );
            insert acc;

            Policy__c pol = new Policy__c(
                Account__c = acc.Id,
                Policy_Type__c = (String) data.get('policyType'),
                Coverage_Amount__c = Decimal.valueOf(String.valueOf(data.get('coverageAmount'))),
                Premium_Amount__c = Decimal.valueOf(String.valueOf(data.get('premiumAmount'))),
                Vehicle_Reg_No__c = (String) data.get('vehicleRegNo'),
                Start_Date__c = Date.today(),
                End_Date__c = Date.today().addYears(1),
                Status__c = 'Active'
            );
            insert pol;

            String responseJson = JSON.serialize(new Map<String, Object>{ 'success' => true, 'policyId' => pol.Id });
            res.statusCode = 201;
            res.responseBody = Blob.valueOf(responseJson);
            IntegrationLoggerService.logCallout('PolicyWebhook_Inbound', req.requestURI, 'POST', 201, reqBody, responseJson);
        } catch (Exception ex) {
            String errJson = JSON.serialize(new Map<String, Object>{ 'success' => false, 'error' => ex.getMessage() });
            res.statusCode = 400;
            res.responseBody = Blob.valueOf(errJson);
            IntegrationLoggerService.logCallout('PolicyWebhook_Inbound', req.requestURI, 'POST', 400, reqBody, errJson);
        }
    }
}
