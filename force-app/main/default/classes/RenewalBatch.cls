public with sharing class RenewalBatch implements Database.Batchable<SObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, Account__c, Agent__c, Premium_Amount__c, Policy_Type__c, End_Date__c
            FROM Policy__c
            WHERE Status__c = 'Active' AND End_Date__c < TODAY
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Policy__c> scope) {
        List<Policy__c> expiredPolicies = new List<Policy__c>();
        List<Opportunity> renewalOpps = new List<Opportunity>();

        for (Policy__c pol : scope) {
            pol.Status__c = 'Expired';
            expiredPolicies.add(pol);

            if (pol.Account__c != null) {
                renewalOpps.add(new Opportunity(
                    Name = 'Renewal - ' + pol.Name,
                    AccountId = pol.Account__c,
                    StageName = 'Qualification',
                    Type = 'Renewal',
                    CloseDate = Date.today().addDays(30),
                    Amount = pol.Premium_Amount__c,
                    Policy__c = pol.Id
                ));
            }
        }
        if (!expiredPolicies.isEmpty()) update expiredPolicies;
        if (!renewalOpps.isEmpty()) insert renewalOpps;
    }

    public void finish(Database.BatchableContext bc) {}
}
