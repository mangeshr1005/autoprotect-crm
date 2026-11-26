public with sharing class ClaimNotificationQueueable implements Queueable {
    private Set<Id> claimIds;

    public ClaimNotificationQueueable(Set<Id> claimIds) {
        this.claimIds = claimIds;
    }

    public void execute(QueueableContext context) {
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        for (Claim__c c : [SELECT Id, Name, Status__c, Claim_Amount__c, Customer_Email__c FROM Claim__c WHERE Id IN :claimIds AND Customer_Email__c != null]) {
            Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
            msg.setToAddresses(new List<String>{ c.Customer_Email__c });
            msg.setSubject('AutoProtect Claim Update: ' + c.Name + ' is now ' + c.Status__c);
            msg.setHtmlBody('<p>Your claim <strong>' + c.Name + '</strong> for amount <strong>' + c.Claim_Amount__c +
                '</strong> has been updated to status: <strong>' + c.Status__c + '</strong>.</p>');
            messages.add(msg);
        }
        if (!messages.isEmpty() && !Test.isRunningTest()) {
            Messaging.sendEmail(messages);
        }
    }
}
