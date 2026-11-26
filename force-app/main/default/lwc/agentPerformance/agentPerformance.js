import { LightningElement, api, wire } from 'lwc';
import getAgentScorecard from '@salesforce/apex/AgentPerformanceController.getAgentScorecard';

export default class AgentPerformance extends LightningElement {
    @api recordId;
    scorecard;

    @wire(getAgentScorecard, { agentId: '$recordId' })
    wiredScore({ data }) { if (data) this.scorecard = data; }
}
