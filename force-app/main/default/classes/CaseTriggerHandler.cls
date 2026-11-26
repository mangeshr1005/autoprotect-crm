public with sharing class CaseTriggerHandler extends TriggerHandler {
    protected override void beforeInsert() {
        List<Case> newCases = (List<Case>) Trigger.new;
        Set<Id> contactIds = new Set<Id>();

        for (Case c : newCases) {
            if (c.ContactId != null) contactIds.add(c.ContactId);
            if (String.isNotBlank(c.Subject) && (c.Subject.containsIgnoreCase('Accident') || c.Subject.containsIgnoreCase('Hospitalization'))) {
                c.Priority = 'High';
            }
        }
        if (contactIds.isEmpty()) return;

        Map<Id, Id> contactToAccount = new Map<Id, Id>();
        for (Contact con : [SELECT Id, AccountId FROM Contact WHERE Id IN :contactIds AND AccountId != null]) {
            contactToAccount.put(con.Id, con.AccountId);
        }

        Map<Id, Id> accountToActivePolicy = new Map<Id, Id>();
        for (Policy__c pol : [SELECT Id, Account__c FROM Policy__c WHERE Account__c IN :contactToAccount.values() AND Status__c = 'Active' ORDER BY CreatedDate DESC]) {
            if (!accountToActivePolicy.containsKey(pol.Account__c)) {
                accountToActivePolicy.put(pol.Account__c, pol.Id);
            }
        }

        for (Case c : newCases) {
            if (c.Policy__c == null && c.ContactId != null && contactToAccount.containsKey(c.ContactId)) {
                Id accId = contactToAccount.get(c.ContactId);
                if (accountToActivePolicy.containsKey(accId)) {
                    c.Policy__c = accountToActivePolicy.get(accId);
                }
            }
        }
    }
}
