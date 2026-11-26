import { LightningElement, wire, track } from 'lwc';
import getPolicyDashboardData from '@salesforce/apex/PolicyController.getPolicyDashboardData';

const COLUMNS = [
    { label: 'Policy #', fieldName: 'Name', type: 'text' },
    { label: 'Type', fieldName: 'Policy_Type__c', type: 'text' },
    { label: 'Status', fieldName: 'Status__c', type: 'text' },
    { label: 'Coverage', fieldName: 'Coverage_Amount__c', type: 'currency' },
    { label: 'Remaining Coverage', fieldName: 'Remaining_Coverage__c', type: 'currency' },
    { label: 'End Date', fieldName: 'End_Date__c', type: 'date' }
];

export default class PolicyDashboard extends LightningElement {
    columns = COLUMNS;
    statusFilter = 'ALL';
    searchKey = '';
    @track policies = [];
    activeCount = 0;
    totalCoverage = 0;
    expiringSoonCount = 0;

    statusOptions = [
        { label: 'All Statuses', value: 'ALL' },
        { label: 'Draft', value: 'Draft' },
        { label: 'Active', value: 'Active' },
        { label: 'Expired', value: 'Expired' },
        { label: 'Cancelled', value: 'Cancelled' }
    ];

    @wire(getPolicyDashboardData, { statusFilter: '$statusFilter', searchKey: '$searchKey' })
    wiredData({ data }) {
        if (data) {
            this.policies = data.policies;
            this.activeCount = data.activeCount;
            this.totalCoverage = data.totalCoverage;
            this.expiringSoonCount = data.expiringSoonCount;
        }
    }

    handleSearchChange(event) { this.searchKey = event.target.value; }
    handleStatusChange(event) { this.statusFilter = event.target.value; }
}
