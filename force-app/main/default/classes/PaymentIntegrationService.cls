public with sharing class PaymentIntegrationService {
    @AuraEnabled
    public static Map<String, Object> processGatewayPayment(Id policyId, Decimal amount, String mode, String gateway) {
        Policy__c pol = [SELECT Id, Name, Account__r.Email__c FROM Policy__c WHERE Id = :policyId LIMIT 1];

        Payment__c pay = new Payment__c(
            Policy__c = policyId,
            Amount__c = amount,
            Payment_Mode__c = mode,
            Payment_Gateway__c = gateway,
            Payment_Date__c = Date.today(),
            Status__c = 'Pending'
        );
        insert pay;

        return executeChargeCallout(pay.Id, pol.Name, amount, mode, gateway, pol.Account__r?.Email__c, 1);
    }

    public static Map<String, Object> executeChargeCallout(Id paymentId, String policyNumber, Decimal amount, String mode, String gateway, String email, Integer attempt) {
        String endpoint = 'callout:Payment_Gateway_API/payments';
        Map<String, Object> payload = new Map<String, Object>{
            'policyId' => policyNumber,
            'amount' => amount,
            'mode' => mode,
            'gateway' => gateway,
            'customerEmail' => email
        };
        String reqBody = JSON.serialize(payload);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(reqBody);
        req.setTimeout(15000);

        Http http = new Http();
        Integer statusCode = 500;
        String resBody = '';
        Map<String, Object> result = new Map<String, Object>();

        try {
            HttpResponse res = http.send(req);
            statusCode = res.getStatusCode();
            resBody = res.getBody();
            IntegrationLoggerService.logCallout('PaymentGateway_Charge', endpoint, 'POST', statusCode, reqBody, resBody);

            if (statusCode >= 200 && statusCode < 300) {
                Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(resBody);
                String txnId = (String) parsed.get('transactionId');
                update new Payment__c(Id = paymentId, Status__c = 'Completed', Transaction_Ref__c = txnId, Payment_Date__c = Date.today());
                result.put('status', 'SUCCESS');
                result.put('transactionId', txnId);
            } else if (statusCode >= 500 && attempt < 3) {
                if (!Test.isRunningTest()) {
                    System.enqueueJob(new PaymentRetryQueueable(paymentId, policyNumber, amount, mode, gateway, email, attempt + 1));
                }
                result.put('status', 'RETRYING');
            } else {
                update new Payment__c(Id = paymentId, Status__c = 'Failed');
                result.put('status', 'FAILED');
            }
        } catch (Exception ex) {
            IntegrationLoggerService.logCallout('PaymentGateway_Charge', endpoint, 'POST', 503, reqBody, ex.getMessage());
            if (attempt < 3 && !Test.isRunningTest()) {
                System.enqueueJob(new PaymentRetryQueueable(paymentId, policyNumber, amount, mode, gateway, email, attempt + 1));
            }
            result.put('status', 'ERROR');
            result.put('message', ex.getMessage());
        }
        return result;
    }
}
