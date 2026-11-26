# AutoProtect CRM Implementation Checklist

- [x] **Phase 1 & 2:** 6 Custom Objects (`Agent__c`, `Policy__c`, `Claim__c`, `Payment__c`, `Service_Request__c`, `Integration_Log__c`) + 5 Extended Standard Objects (`Lead`, `Account`, `Contact`, `Opportunity`, `Case`) with Roll-Up Summary & Formula fields.
- [x] **Phase 3:** Controlling/Dependent picklists (`Policy_Type__c -> Coverage_Option__c`, `Claim_Type__c -> Claim_Sub_Type__c`, `Payment_Mode__c -> Payment_Gateway__c`) and 7 Record Types.
- [x] **Phase 4:** Enterprise Role Hierarchy (`CEO` down to Regional Sales/Service/Finance roles) and 4 Permission Sets.
- [x] **Phase 5:** 17 Data Quality Validation Rules across all standard and custom objects.
- [x] **Phase 6:** Lightning Record-Triggered & Screen Flows (`Auto_Assign_Case_Priority`, `Activate_Policy_On_Payment`, `Premium_Calculator_Flow`).
- [x] **Phase 7:** Bulkified Trigger Framework + 5 Triggers (`PolicyTrigger`, `ClaimTrigger`, `PaymentTrigger`, `OpportunityTrigger`, `CaseTrigger`) + Async Apex (`RenewalBatch`, `ReminderScheduler`, `CommissionCalcBatch`, `ClaimNotificationQueueable`, `PaymentRetryQueueable`).
- [x] **Phase 8:** Outbound `PaymentIntegrationService`, Inbound `@RestResource` Webhooks (`PolicyWebhookService`, `PaymentWebhookListener`), `IntegrationLoggerService`, and `Payment_Gateway_API` Named Credential.
- [x] **Phase 9:** 5 Lightning Web Components (`policyDashboard`, `claimForm`, `paymentPortal`, `agentPerformance`, `policyRenewal`), 6 Custom Tabs, and `AutoProtect_CRM` Lightning Application.
- [x] **Phase 10:** `AutoProtectSuiteTest` test class, 200-row sample CSV datasets per object, deployment bash script, and GitHub Actions CI/CD workflow.
