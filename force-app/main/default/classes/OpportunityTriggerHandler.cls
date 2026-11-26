public with sharing class OpportunityTriggerHandler extends TriggerHandler {
    protected override void afterUpdate() {
        List<Opportunity> newOpps = (List<Opportunity>) Trigger.new;
        Map<Id, Opportunity> oldMap = (Map<Id, Opportunity>) Trigger.oldMap;
        List<Opportunity> wonOpps = new List<Opportunity>();

        for (Opportunity opp : newOpps) {
            if (opp.StageName == 'Closed Won' && oldMap.get(opp.Id).StageName != 'Closed Won' && !opp.Policy_Created__c && opp.Policy__c == null) {
                wonOpps.add(opp);
            }
        }
        if (wonOpps.isEmpty()) return;

        Map<Id, Policy__c> oppToPolicy = new Map<Id, Policy__c>();
        for (Opportunity opp : wonOpps) {
            oppToPolicy.put(opp.Id, new Policy__c(
                Account__c = opp.AccountId,
                Opportunity__c = opp.Id,
                Policy_Type__c = 'Life',
                Coverage_Amount__c = opp.Amount != null ? opp.Amount * 10 : 100000,
                Premium_Amount__c = opp.Amount != null ? opp.Amount : 5000,
                Start_Date__c = Date.today(),
                End_Date__c = Date.today().addYears(1),
                Status__c = 'Draft'
            ));
        }
        insert oppToPolicy.values();

        List<Opportunity> oppsToSync = new List<Opportunity>();
        for (Id oppId : oppToPolicy.keySet()) {
            oppsToSync.add(new Opportunity(
                Id = oppId,
                Policy__c = oppToPolicy.get(oppId).Id,
                Policy_Created__c = true
            ));
        }
        TriggerHandler.bypass('OpportunityTriggerHandler');
        update oppsToSync;
        TriggerHandler.clearBypass('OpportunityTriggerHandler');
    }
}
