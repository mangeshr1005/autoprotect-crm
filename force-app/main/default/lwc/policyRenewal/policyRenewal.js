import { LightningElement, api, wire } from 'lwc';
import getExpiringPolicies from '@salesforce/apex/PolicyController.getExpiringPolicies';

export default class PolicyRenewal extends LightningElement {
    @api recordId;
    expiringPolicies = [];

    @wire(getExpiringPolicies, { recordId: '$recordId' })
    wiredPolicies({ data }) { if (data) this.expiringPolicies = data; }
}
