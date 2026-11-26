public with sharing class ClaimController {
    @AuraEnabled(cacheable=true)
    public static Policy__c getPolicyCoverageDetails(Id policyId) {
        return [SELECT Id, Name, Status__c, Coverage_Amount__c, Approved_Claims_Total__c, Remaining_Coverage__c FROM Policy__c WHERE Id = :policyId LIMIT 1];
    }

    @AuraEnabled
    public static Id submitClaim(Id policyId, String claimType, String subType, Decimal amount, Date claimDate, String description) {
        Claim__c claim = new Claim__c(
            Policy__c = policyId,
            Claim_Type__c = claimType,
            Claim_Sub_Type__c = subType,
            Claim_Amount__c = amount,
            Claim_Date__c = claimDate,
            Description__c = description,
            Status__c = 'Pending'
        );
        insert claim;
        return claim.Id;
    }
}
