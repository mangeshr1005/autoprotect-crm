public without sharing class IntegrationLoggerService {
    public static void logCallout(String name, String endpoint, String method, Integer statusCode, String reqBody, String resBody) {
        String status = (statusCode >= 200 && statusCode < 300) ? 'Success' : (statusCode >= 500 ? 'Retrying' : 'Failure');
        insert new Integration_Log__c(
            Integration_Name__c = name,
            Endpoint_URL__c = endpoint?.abbreviate(255),
            HTTP_Method__c = method,
            Status_Code__c = statusCode,
            Status__c = status,
            Request_Payload__c = reqBody?.abbreviate(32768),
            Response_Payload__c = resBody?.abbreviate(32768)
        );
    }
}
