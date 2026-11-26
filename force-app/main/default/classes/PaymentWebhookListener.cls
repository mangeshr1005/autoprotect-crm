@RestResource(urlMapping='/api/v1/autoprotect/payment-callback/*')
global with sharing class PaymentWebhookListener {
    @HttpPost
    global static void handlePaymentCallback() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String reqBody = req.requestBody != null ? req.requestBody.toString() : '';

        try {
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(reqBody);
            String txnId = (String) payload.get('transactionId');
            String gatewayStatus = (String) payload.get('status');

            List<Payment__c> payments = [SELECT Id, Status__c FROM Payment__c WHERE Transaction_Ref__c = :txnId LIMIT 1];
            if (payments.isEmpty()) {
                res.statusCode = 404;
                res.responseBody = Blob.valueOf('{"error":"Transaction not found"}');
                return;
            }

            payments[0].Status__c = (gatewayStatus == 'SUCCESS') ? 'Completed' : 'Failed';
            update payments[0];

            res.statusCode = 200;
            res.responseBody = Blob.valueOf('{"acknowledged":true}');
            IntegrationLoggerService.logCallout('PaymentCallback_Inbound', req.requestURI, 'POST', 200, reqBody, '{"acknowledged":true}');
        } catch (Exception ex) {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf('{"error":"' + ex.getMessage() + '"}');
            IntegrationLoggerService.logCallout('PaymentCallback_Inbound', req.requestURI, 'POST', 400, reqBody, ex.getMessage());
        }
    }
}
