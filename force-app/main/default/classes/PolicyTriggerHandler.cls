public with sharing class PolicyTriggerHandler extends TriggerHandler {
    private List<Policy__c> newPolicies;
    private Map<Id, Policy__c> oldPolicyMap;

    public PolicyTriggerHandler() {
        this.newPolicies = (List<Policy__c>) Trigger.new;
        this.oldPolicyMap = (Map<Id, Policy__c>) Trigger.oldMap;
    }

    protected override void beforeInsert() { validatePolicies(newPolicies); }
    protected override void beforeUpdate() { validatePolicies(newPolicies); }
    protected override void afterInsert() {
        createInitialPendingPayments(newPolicies);
        syncAccountActivePolicyCount(newPolicies, null);
    }
    protected override void afterUpdate() {
        syncCustomerInceptionDates(newPolicies, oldPolicyMap);
        syncAccountActivePolicyCount(newPolicies, oldPolicyMap);
    }

    private void validatePolicies(List<Policy__c> policies) {
        for (Policy__c pol : policies) {
            if (pol.Start_Date__c != null && pol.End_Date__c != null && pol.End_Date__c <= pol.Start_Date__c) {
                pol.End_Date__c.addError('Policy End Date must be later than Start Date.');
            }
            if (pol.Policy_Type__c == 'Vehicle' && String.isBlank(pol.Vehicle_Reg_No__c)) {
                pol.Vehicle_Reg_No__c.addError('Enter Vehicle Registration Number for Vehicle Policies.');
            }
        }
    }

    private void createInitialPendingPayments(List<Policy__c> policies) {
        Id premiumRtId = Schema.SObjectType.Payment__c.getRecordTypeInfosByDeveloperName().get('Premium_Payment')?.getRecordTypeId();
        List<Payment__c> initialPayments = new List<Payment__c>();

        for (Policy__c pol : policies) {
            if (pol.Premium_Amount__c != null && pol.Premium_Amount__c > 0) {
                Payment__c pay = new Payment__c(
                    Policy__c = pol.Id,
                    Amount__c = pol.Premium_Amount__c,
                    Payment_Date__c = Date.today(),
                    Status__c = 'Pending'
                );
                if (premiumRtId != null) pay.RecordTypeId = premiumRtId;
                initialPayments.add(pay);
            }
        }
        if (!initialPayments.isEmpty()) insert initialPayments;
    }

    private void syncCustomerInceptionDates(List<Policy__c> policies, Map<Id, Policy__c> oldMap) {
        Map<Id, Date> accountStartDates = new Map<Id, Date>();
        for (Policy__c pol : policies) {
            Policy__c oldPol = oldMap.get(pol.Id);
            if (pol.Status__c == 'Active' && oldPol.Status__c != 'Active' && pol.Account__c != null && pol.Start_Date__c != null) {
                if (!accountStartDates.containsKey(pol.Account__c) || pol.Start_Date__c < accountStartDates.get(pol.Account__c)) {
                    accountStartDates.put(pol.Account__c, pol.Start_Date__c);
                }
            }
        }
        if (accountStartDates.isEmpty()) return;

        List<Account> accountsToUpdate = new List<Account>();
        for (Account acc : [SELECT Id, Customer_Since__c FROM Account WHERE Id IN :accountStartDates.keySet()]) {
            if (acc.Customer_Since__c == null) {
                acc.Customer_Since__c = accountStartDates.get(acc.Id);
                accountsToUpdate.add(acc);
            }
        }
        if (!accountsToUpdate.isEmpty()) update accountsToUpdate;
    }

    private void syncAccountActivePolicyCount(List<Policy__c> policies, Map<Id, Policy__c> oldMap) {
        Set<Id> accountIds = new Set<Id>();
        for (Policy__c pol : policies) {
            if (pol.Account__c != null) accountIds.add(pol.Account__c);
            if (oldMap != null && oldMap.get(pol.Id).Account__c != null) accountIds.add(oldMap.get(pol.Id).Account__c);
        }
        if (accountIds.isEmpty()) return;

        Map<Id, Integer> activeCounts = new Map<Id, Integer>();
        for (AggregateResult ar : [SELECT Account__c accId, COUNT(Id) cnt FROM Policy__c WHERE Account__c IN :accountIds AND Status__c = 'Active' GROUP BY Account__c]) {
            activeCounts.put((Id) ar.get('accId'), (Integer) ar.get('cnt'));
        }

        List<Account> accsToUpdate = new List<Account>();
        for (Id accId : accountIds) {
            accsToUpdate.add(new Account(
                Id = accId,
                Total_Active_Policies__c = activeCounts.containsKey(accId) ? activeCounts.get(accId) : 0
            ));
        }
        if (!accsToUpdate.isEmpty()) update accsToUpdate;
    }
}
