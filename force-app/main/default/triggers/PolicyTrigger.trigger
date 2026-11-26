trigger PolicyTrigger on Policy__c (before insert, before update, after insert, after update) {
    new PolicyTriggerHandler().run();
}
