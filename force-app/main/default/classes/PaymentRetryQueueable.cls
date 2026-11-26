public class PaymentRetryQueueable implements Queueable, Database.AllowsCallouts {
    private Id paymentId;
    private String policyNumber, mode, gateway, email;
    private Decimal amount;
    private Integer attempt;

    public PaymentRetryQueueable(Id paymentId, String policyNumber, Decimal amount, String mode, String gateway, String email, Integer attempt) {
        this.paymentId = paymentId;
        this.policyNumber = policyNumber;
        this.amount = amount;
        this.mode = mode;
        this.gateway = gateway;
        this.email = email;
        this.attempt = attempt;
    }

    public void execute(QueueableContext context) {
        PaymentIntegrationService.executeChargeCallout(paymentId, policyNumber, amount, mode, gateway, email, attempt);
    }
}
