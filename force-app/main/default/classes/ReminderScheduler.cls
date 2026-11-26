public with sharing class ReminderScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new RenewalBatch(), 200);

        Date targetExpiry = Date.today().addDays(30);
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Policy__c pol : [
            SELECT Id, Name, End_Date__c, Premium_Amount__c, Account__r.Name, Account__r.Email__c
            FROM Policy__c
            WHERE Status__c = 'Active' AND End_Date__c = :targetExpiry AND Account__r.Email__c != null
            LIMIT 200
        ]) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>{ pol.Account__r.Email__c });
            mail.setSubject('Action Required: AutoProtect Policy ' + pol.Name + ' Expires in 30 Days');
            mail.setPlainTextBody('Dear ' + pol.Account__r.Name + ', Your policy ' + pol.Name +
                ' expires on ' + String.valueOf(pol.End_Date__c) + '. Please renew to continue coverage.');
            emails.add(mail);
        }
        if (!emails.isEmpty() && !Test.isRunningTest()) {
            Messaging.sendEmail(emails);
        }
    }
}
