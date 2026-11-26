public with sharing class PaymentTriggerHandler extends TriggerHandler {
    protected override void afterInsert() { activateParentPolicies((List<Payment__c>) Trigger.new, null); }
    protected override void afterUpdate() { activateParentPolicies((List<Payment__c>) Trigger.new, (Map<Id, Payment__c>) Trigger.oldMap); }

    private void activateParentPolicies(List<Payment__c> payments, Map<Id, Payment__c> oldMap) {
        Id payoutRtId = Schema.SObjectType.Payment__c.getRecordTypeInfosByDeveloperName().get('Claim_Payout')?.getRecordTypeId();
        Set<Id> policyIdsToActivate = new Set<Id>();

        for (Payment__c pay : payments) {
            Boolean isNewlyCompleted = (oldMap == null && pay.Status__c == 'Completed') ||
                (oldMap != null && pay.Status__c == 'Completed' && oldMap.get(pay.Id).Status__c != 'Completed');
            if (isNewlyCompleted && pay.Policy__c != null && (payoutRtId == null || pay.RecordTypeId != payoutRtId)) {
                policyIdsToActivate.add(pay.Policy__c);
            }
        }
        if (policyIdsToActivate.isEmpty()) return;

        List<Policy__c> policiesToUpdate = new List<Policy__c>();
        for (Policy__c pol : [SELECT Id, Status__c FROM Policy__c WHERE Id IN :policyIdsToActivate AND Status__c != 'Active']) {
            pol.Status__c = 'Active';
            policiesToUpdate.add(pol);
        }
        if (!policiesToUpdate.isEmpty()) update policiesToUpdate;
    }
}
