public with sharing class CommissionCalcBatch implements Database.Batchable<SObject>, Database.Stateful {
    private Map<Id, Decimal> agentPremiumTotals = new Map<Id, Decimal>();

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date firstOfMonth = Date.today().toStartOfMonth();
        return Database.getQueryLocator([
            SELECT Id, Amount__c, Policy__r.Agent__c
            FROM Payment__c
            WHERE Status__c = 'Completed'
              AND Payment_Date__c >= :firstOfMonth
              AND Policy__r.Agent__c != null
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Payment__c> scope) {
        for (Payment__c pay : scope) {
            Id agentId = pay.Policy__r.Agent__c;
            Decimal current = agentPremiumTotals.containsKey(agentId) ? agentPremiumTotals.get(agentId) : 0;
            agentPremiumTotals.put(agentId, current + (pay.Amount__c != null ? pay.Amount__c : 0));
        }
    }

    public void finish(Database.BatchableContext bc) {
        if (agentPremiumTotals.isEmpty()) return;
        List<Integration_Log__c> auditLogs = new List<Integration_Log__c>();
        for (Agent__c agt : [SELECT Id, Name, Agent_Name__c, Commission_Rate__c FROM Agent__c WHERE Id IN :agentPremiumTotals.keySet()]) {
            Decimal totalSales = agentPremiumTotals.get(agt.Id);
            Decimal rate = agt.Commission_Rate__c != null ? agt.Commission_Rate__c / 100 : 0;
            Decimal commission = (totalSales * rate).setScale(2);
            auditLogs.add(new Integration_Log__c(
                Integration_Name__c = 'Monthly_Commission_Rollup',
                Status__c = 'Success',
                Status_Code__c = 200,
                Response_Payload__c = JSON.serialize(new Map<String, Object>{
                    'agentCode' => agt.Name,
                    'agentName' => agt.Agent_Name__c,
                    'monthlyPremiumCollected' => totalSales,
                    'commissionEarned' => commission
                })
            ));
        }
        if (!auditLogs.isEmpty()) insert auditLogs;
    }
}
