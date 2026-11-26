# Architectural & Implementation Assumptions

1. **API Version:** Standardized on Salesforce Metadata API `v62.0` for full compatibility with modern Developer Edition orgs.
2. **External IDs for Data Loading:** Added `External_ID__c` fields on `Agent__c`, `Account`, and `Policy__c` so bulk CSV imports link child `Contact`, `Policy__c`, and `Claim__c` records cleanly without manual ID remapping.
3. **Named Credential Security:** `Payment_Gateway_API` is configured with `NoAuthentication` in source metadata so it deploys cleanly without secret errors; configure the External Credential Bearer Token in Setup post-deployment.
4. **Trigger & Flow Coexistence:** `TriggerHandler` enforces a `MAX_LOOPS = 3` recursion guard so Record-Triggered Flows and Apex Triggers operate together without hitting governor limits.
