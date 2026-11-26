public with sharing class PolicyController {
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getPolicyDashboardData(String statusFilter, String searchKey) {
        String searchPattern = '%' + (String.isBlank(searchKey) ? '' : String.escapeSingleQuotes(searchKey.trim())) + '%';
        String query = 'SELECT Id, Name, Policy_Type__c, Coverage_Amount__c, Remaining_Coverage__c, Premium_Amount__c, Start_Date__c, End_Date__c, Status__c, Account__r.Name FROM Policy__c WHERE Name LIKE :searchPattern';
        if (String.isNotBlank(statusFilter) && statusFilter != 'ALL') {
            query += ' AND Status__c = :statusFilter';
        }
        query += ' ORDER BY CreatedDate DESC LIMIT 200';
        List<Policy__c> policies = Database.query(query);

        AggregateResult[] agg = [SELECT COUNT(Id) activeCnt, SUM(Coverage_Amount__c) totalCov FROM Policy__c WHERE Status__c = 'Active'];
        Integer expiringCount = [SELECT COUNT() FROM Policy__c WHERE Status__c = 'Active' AND End_Date__c <= NEXT_N_DAYS:30];

        return new Map<String, Object>{
            'policies' => policies,
            'activeCount' => agg[0].get('activeCnt'),
            'totalCoverage' => agg[0].get('totalCov') != null ? agg[0].get('totalCov') : 0,
            'expiringSoonCount' => expiringCount
        };
    }

    @AuraEnabled(cacheable=true)
    public static List<Policy__c> getExpiringPolicies(Id recordId) {
        return [
            SELECT Id, Name, Policy_Type__c, End_Date__c, Premium_Amount__c, Status__c
            FROM Policy__c
            WHERE (Id = :recordId OR Account__c = :recordId)
              AND Status__c = 'Active'
              AND End_Date__c <= NEXT_N_DAYS:30
            ORDER BY End_Date__c ASC
        ];
    }
}
