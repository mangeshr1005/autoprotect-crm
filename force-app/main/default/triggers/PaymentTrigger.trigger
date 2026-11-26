trigger PaymentTrigger on Payment__c (after insert, after update) {
    new PaymentTriggerHandler().run();
}
