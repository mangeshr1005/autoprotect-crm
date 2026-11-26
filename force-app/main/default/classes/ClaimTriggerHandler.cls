public with sharing class ClaimTriggerHandler extends TriggerHandler {
    private List<Claim__c> newClaims;
    private Map<Id, Claim__c> oldClaimMap;

    public ClaimTriggerHandler() {
        this.newClaims = (List<Claim__c>) Trigger.new;
        this.oldClaimMap = (Map<Id, Claim__c>) Trigger.oldMap;
    }

    protected override void beforeInsert() { validateClaimCoverage(newClaims, null); }
    protected override void beforeUpdate() { validateClaimCoverage(newClaims, oldClaimMap); }
    protected override void afterUpdate() { handleClaimStatusTransitions(newClaims, oldClaimMap); }

    private void validateClaimCoverage(List<Claim__c> claims, Map<Id, Claim__c> oldMap) {
        Set<Id> policyIds = new Set<Id>();
        for (Claim__c c : claims) {
            if (c.Policy__c != null) policyIds.add(c.Policy__c);
        }
        if (policyIds.isEmpty()) return;

        Map<Id, Policy__c> policyMap = new Map<Id, Policy__c>([
            SELECT Id, Status__c, Start_Date__c, Remaining_Coverage__c, Account__r.Email__c
            FROM Policy__c
            WHERE Id IN :policyIds
        ]);

        for (Claim__c c : claims) {
            Policy__c parentPol = policyMap.get(c.Policy__c);
            if (parentPol == null) continue;

            if (String.isBlank(c.Customer_Email__c) && parentPol.Account__r?.Email__c != null) {
                c.Customer_Email__c = parentPol.Account__r.Email__c;
            }
            if (parentPol.Status__c != 'Active') {
                c.addError('Claims can only be submitted against Active policies.');
            }
            if (c.Claim_Date__c != null && parentPol.Start_Date__c != null && c.Claim_Date__c < parentPol.Start_Date__c) {
                c.Claim_Date__c.addError('Claim Date cannot be earlier than Policy Start Date.');
            }
            Boolean amountChanged = (oldMap == null || c.Claim_Amount__c != oldMap.get(c.Id).Claim_Amount__c);
            if (amountChanged && c.Claim_Amount__c != null && parentPol.Remaining_Coverage__c != null && c.Claim_Amount__c > parentPol.Remaining_Coverage__c) {
                c.Claim_Amount__c.addError('Claim Amount cannot exceed the Remaining Coverage.');
            }
        }
    }

    private void handleClaimStatusTransitions(List<Claim__c> claims, Map<Id, Claim__c> oldMap) {
        Id payoutRtId = Schema.SObjectType.Payment__c.getRecordTypeInfosByDeveloperName().get('Claim_Payout')?.getRecordTypeId();
        List<Payment__c> payoutsToInsert = new List<Payment__c>();
        Set<Id> notifyClaimIds = new Set<Id>();

        for (Claim__c c : claims) {
            Claim__c oldClaim = oldMap.get(c.Id);
            if (c.Status__c != oldClaim.Status__c) {
                if (c.Status__c == 'Approved') {
                    Payment__c payout = new Payment__c(
                        Policy__c = c.Policy__c,
                        Amount__c = c.Claim_Amount__c,
                        Payment_Date__c = Date.today(),
                        Status__c = 'Pending'
                    );
                    if (payoutRtId != null) payout.RecordTypeId = payoutRtId;
                    payoutsToInsert.add(payout);
                }
                if (c.Status__c == 'Under Review' || c.Status__c == 'Approved' || c.Status__c == 'Rejected') {
                    notifyClaimIds.add(c.Id);
                }
            }
        }

        if (!payoutsToInsert.isEmpty()) insert payoutsToInsert;
        if (!notifyClaimIds.isEmpty() && !System.isQueueable() && !System.isBatch()) {
            System.enqueueJob(new ClaimNotificationQueueable(notifyClaimIds));
        }
    }
}
