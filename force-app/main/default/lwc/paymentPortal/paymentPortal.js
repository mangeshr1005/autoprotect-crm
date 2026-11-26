import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import processGatewayPayment from '@salesforce/apex/PaymentIntegrationService.processGatewayPayment';

const GATEWAY_MAP = {
    'Credit Card': [{ label: 'Razorpay', value: 'Razorpay' }, { label: 'PayU', value: 'PayU' }],
    'Debit Card': [{ label: 'Razorpay', value: 'Razorpay' }, { label: 'PayU', value: 'PayU' }],
    'UPI': [{ label: 'Google Pay', value: 'Google Pay' }, { label: 'PhonePe', value: 'PhonePe' }],
    'NetBanking': [{ label: 'HDFC', value: 'HDFC' }, { label: 'ICICI', value: 'ICICI' }]
};

export default class PaymentPortal extends LightningElement {
    @api recordId;
    amount = 5000;
    mode = 'UPI';
    gateway = 'Google Pay';
    txnReference;
    isProcessing = false;

    modeOptions = [
        { label: 'UPI', value: 'UPI' },
        { label: 'Credit Card', value: 'Credit Card' },
        { label: 'Debit Card', value: 'Debit Card' },
        { label: 'NetBanking', value: 'NetBanking' }
    ];

    get gatewayOptions() { return GATEWAY_MAP[this.mode] || []; }

    handleAmountChange(e) { this.amount = e.target.value; }
    handleModeChange(e) { this.mode = e.detail.value; this.gateway = this.gatewayOptions[0]?.value; }
    handleGatewayChange(e) { this.gateway = e.detail.value; }

    async handlePay() {
        this.isProcessing = true;
        try {
            const res = await processGatewayPayment({
                policyId: this.recordId,
                amount: parseFloat(this.amount),
                mode: this.mode,
                gateway: this.gateway
            });
            if (res.status === 'SUCCESS') {
                this.txnReference = res.transactionId;
                this.dispatchEvent(new ShowToastEvent({ title: 'Payment Successful', message: 'Ref: ' + res.transactionId, variant: 'success' }));
            } else {
                this.dispatchEvent(new ShowToastEvent({ title: 'Gateway Notice', message: 'Payment status: ' + res.status, variant: 'warning' }));
            }
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Payment Failed', message: error.body?.message || error.message, variant: 'error' }));
        } finally {
            this.isProcessing = false;
        }
    }
}
