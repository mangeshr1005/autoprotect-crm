@IsTest
private class AutoProtectSuiteTest {
    private class PaymentGatewayMock implements HttpCalloutMock {
        private Integer code;
        public PaymentGatewayMock(Integer code) { this.code = code; }
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(code);
            res.setBody('{"transactionId":"TXN-RZP-987654321","status":"SUCCESS"}');
            return res;
        }
    }

    @TestSetup
    static void setupTestData() {
        Agent__c agent = new Agent__c(
            Agent_Name__c = 'Vikram Sharma',
            Email__c = 'vikram.sharma@autoprotect.example.com',
            Phone__c = '9876543210',
            Region__c = 'West',
            Commission_Rate__c = 10.0,
            License_Expiry_Date__c = Date.today().addYears(2),
            Training_Completed__c = true
        );
        insert agent;

        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(
                Name = 'Policyholder ' + i,
                Customer_Type__c = 'Individual',
                Email__c = 'holder' + i + '@example.com',
                PAN__c = 'ABCDE' + String.valueOf(1000 + i).left(4) + 'F',
                Agent__c = agent.Id
            ));
        }
        insert accounts;
    }

    @IsTest
    static void testBulkPolicyCreationAndActivation() {
        List<Account> accs = [SELECT Id FROM Account LIMIT 200];
        Agent__c agt = [SELECT Id FROM Agent__c LIMIT 1];
        List<Policy__c> policies = new List<Policy__c>();

        for (Account acc : accs) {
            policies.add(new Policy__c(
                Account__c = acc.Id,
                Agent__c = agt.Id,
                Policy_Type__c = 'Health',
                Coverage_Amount__c = 500000,
                Premium_Amount__c = 12000,
                Start_Date__c = Date.today(),
                End_Date__c = Date.today().addYears(1),
                Status__c = 'Draft'
            ));
        }

        Test.startTest();
        insert policies;
        List<Payment__c> payments = [SELECT Id, Status__c FROM Payment__c WHERE Policy__c IN :policies];
        System.assertEquals(200, payments.size());

        for (Payment__c p : payments) p.Status__c = 'Completed';
        update payments;
        Test.stopTest();

        System.assertEquals(200, [SELECT COUNT() FROM Policy__c WHERE Status__c = 'Active']);
        Map<String, Object> dashData = PolicyController.getPolicyDashboardData('Active', '');
        System.assertEquals(200, dashData.get('activeCount'));
        Map<String, Object> score = AgentPerformanceController.getAgentScorecard(agt.Id);
        System.assertEquals(200, score.get('boundPolicies'));
    }

    @IsTest
    static void testClaimValidationAndPayout() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Policy__c pol = new Policy__c(
            Account__c = acc.Id,
            Policy_Type__c = 'Vehicle',
            Vehicle_Reg_No__c = 'MH12AB1234',
            Coverage_Amount__c = 200000,
            Premium_Amount__c = 8000,
            Start_Date__c = Date.today().addDays(-10),
            End_Date__c = Date.today().addDays(20),
            Status__c = 'Active'
        );
        insert pol;

        Test.startTest();
        Policy__c cov = ClaimController.getPolicyCoverageDetails(pol.Id);
        System.assertEquals(200000, cov.Remaining_Coverage__c);
        List<Policy__c> exp = PolicyController.getExpiringPolicies(acc.Id);
        System.assertEquals(1, exp.size());

        Id claimId = ClaimController.submitClaim(pol.Id, 'Accident', 'Minor Damage', 45000, Date.today(), 'Bumper repair');
        update new Claim__c(Id = claimId, Status__c = 'Approved');
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Payment__c WHERE Policy__c = :pol.Id AND Amount__c = 45000]);
    }

    @IsTest
    static void testOpportunityAndCaseTriggers() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = new Contact(LastName = 'Patel', AccountId = acc.Id, Email = 'patel@example.com');
        insert con;

        Opportunity opp = new Opportunity(
            Name = 'New Life Quote',
            AccountId = acc.Id,
            StageName = 'Proposal/Quote',
            CloseDate = Date.today().addDays(10),
            Amount = 10000
        );
        insert opp;

        Test.startTest();
        opp.StageName = 'Closed Won';
        update opp;

        Opportunity updatedOpp = [SELECT Policy__c, Policy_Created__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(true, updatedOpp.Policy_Created__c);
        update new Policy__c(Id = updatedOpp.Policy__c, Status__c = 'Active');

        Case cs = new Case(ContactId = con.Id, Subject = 'Accident Claim Support', Status = 'New');
        insert cs;
        Test.stopTest();

        Case insertedCase = [SELECT Priority, Policy__c FROM Case WHERE Id = :cs.Id];
        System.assertEquals('High', insertedCase.Priority);
        System.assertEquals(updatedOpp.Policy__c, insertedCase.Policy__c);
    }

    @IsTest
    static void testPaymentCalloutAndWebhooks() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Policy__c pol = new Policy__c(
            Account__c = acc.Id,
            Policy_Type__c = 'Life',
            Coverage_Amount__c = 1000000,
            Premium_Amount__c = 15000,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addYears(1),
            Status__c = 'Draft'
        );
        insert pol;

        Test.setMock(HttpCalloutMock.class, new PaymentGatewayMock(200));
        Test.startTest();
        Map<String, Object> calloutRes = PaymentIntegrationService.processGatewayPayment(pol.Id, 15000, 'UPI', 'Google Pay');
        System.assertEquals('SUCCESS', calloutRes.get('status'));

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/api/v1/autoprotect/policies/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"customerName":"Webhook Client","email":"wh@example.com","pan":"ZZZZZ9999Z","policyType":"Home","coverageAmount":1500000,"premiumAmount":9500}');
        RestContext.request = req;
        RestContext.response = new RestResponse();
        PolicyWebhookService.syncExternalPolicy();
        System.assertEquals(201, RestContext.response.statusCode);

        RestRequest cbReq = new RestRequest();
        cbReq.requestURI = '/services/apexrest/api/v1/autoprotect/payment-callback/';
        cbReq.httpMethod = 'POST';
        cbReq.requestBody = Blob.valueOf('{"transactionId":"TXN-RZP-987654321","status":"SUCCESS"}');
        RestContext.request = cbReq;
        RestContext.response = new RestResponse();
        PaymentWebhookListener.handlePaymentCallback();
        System.assertEquals(200, RestContext.response.statusCode);
        Test.stopTest();
    }

    @IsTest
    static void testBatchAndScheduler() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Policy__c expiredPol = new Policy__c(
            Account__c = acc.Id,
            Policy_Type__c = 'Life',
            Coverage_Amount__c = 500000,
            Premium_Amount__c = 6000,
            Start_Date__c = Date.today().addYears(-1),
            End_Date__c = Date.today().addDays(-1),
            Status__c = 'Active'
        );
        insert expiredPol;

        Test.startTest();
        System.schedule('Daily Renewal Check', '0 0 6 * * ?', new ReminderScheduler());
        Database.executeBatch(new CommissionCalcBatch(), 200);
        Test.stopTest();

        System.assertEquals('Expired', [SELECT Status__c FROM Policy__c WHERE Id = :expiredPol.Id].Status__c);
    }
}
