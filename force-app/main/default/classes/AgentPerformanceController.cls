public with sharing class AgentPerformanceController {
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getAgentScorecard(Id agentId) {
        Agent__c agt = [SELECT Id, Agent_Name__c, Region__c, Commission_Rate__c FROM Agent__c WHERE Id = :agentId LIMIT 1];
        Integer boundCount = [SELECT COUNT() FROM Policy__c WHERE Agent__c = :agentId AND Status__c = 'Active'];
        AggregateResult[] payAgg = [SELECT SUM(Amount__c) totalCollected FROM Payment__c WHERE Policy__r.Agent__c = :agentId AND Status__c = 'Completed'];

        Decimal collected = payAgg[0].get('totalCollected') != null ? (Decimal) payAgg[0].get('totalCollected') : 0;
        Decimal rate = agt.Commission_Rate__c != null ? agt.Commission_Rate__c / 100 : 0;

        return new Map<String, Object>{
            'agentName' => agt.Agent_Name__c,
            'region' => agt.Region__c,
            'boundPolicies' => boundCount,
            'totalPremiumCollected' => collected,
            'earnedCommission' => (collected * rate).setScale(2)
        };
    }
}
