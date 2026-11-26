import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPolicyCoverageDetails from '@salesforce/apex/ClaimController.getPolicyCoverageDetails';
import submitClaim from '@salesforce/apex/ClaimController.submitClaim';

const SUBTYPE_MAP = {
    Accident: [
        { label: 'Minor Damage', value: 'Minor Damage' },
        { label: 'Total Loss', value: 'Total Loss' },
        { label: 'Third-Party Liability', value: 'Third-Party Liability' }
    ],
    Health: [
        { label: 'Hospitalization', value: 'Hospitalization' },
        { label: 'Daycare Surgery', value: 'Daycare Surgery' },
        { label: 'Maternity', value: 'Maternity' }
    ],
    Theft: [
        { label: 'Vehicle Theft', value: 'Vehicle Theft' },
        { label: 'Burglary / Contents', value: 'Burglary / Contents' }
    ]
};

export default class ClaimForm extends LightningElement {
    @api recordId;
    policy;
    claimType = 'Accident';
    subType = 'Minor Damage';
    amount;
    claimDate;
    description;

    claimTypeOptions = [
        { label: 'Accident', value: 'Accident' },
        { label: 'Health', value: 'Health' },
        { label: 'Theft', value: 'Theft' }
    ];

    get subTypeOptions() { return SUBTYPE_MAP[this.claimType] || []; }

    @wire(getPolicyCoverageDetails, { policyId: '$recordId' })
    wiredPolicy({ data }) { if (data) this.policy = data; }

    handleTypeChange(e) { this.claimType = e.detail.value; this.subType = this.subTypeOptions[0]?.value; }
    handleSubTypeChange(e) { this.subType = e.detail.value; }
    handleAmountChange(e) { this.amount = e.target.value; }
    handleDateChange(e) { this.claimDate = e.target.value; }
    handleDescChange(e) { this.description = e.target.value; }

    async handleSubmit() {
        try {
            const claimId = await submitClaim({
                policyId: this.recordId,
                claimType: this.claimType,
                subType: this.subType,
                amount: parseFloat(this.amount),
                claimDate: this.claimDate,
                description: this.description
            });
            this.dispatchEvent(new ShowToastEvent({ title: 'Claim Submitted', message: 'Claim ID: ' + claimId, variant: 'success' }));
        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Validation Error', message: error.body?.message || error.message, variant: 'error' }));
        }
    }
}
