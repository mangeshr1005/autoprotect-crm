trigger ClaimTrigger on Claim__c (before insert, before update, after update) {
    new ClaimTriggerHandler().run();
}
