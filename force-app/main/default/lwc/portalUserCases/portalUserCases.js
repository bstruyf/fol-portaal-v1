import { LightningElement, wire, track } from 'lwc';
import getPortalUserCases from '@salesforce/apex/PortalUserCasesController.getPortalUserCases';

export default class PortalUserCases extends LightningElement {
    @track cases;
    @track error;
    connectedCallback() {
        console.log('🚀 LWC component is geladen!');
    }
    get jsonCases() {
        return this.cases ? JSON.stringify(this.cases, null, 2) : 'Geen data ontvangen';
    }
    @wire(getPortalUserCases)
    wiredCases({ error, data }) {
        if (data) {
            this.cases = data;
            this.error = undefined;
        } else if (error) {
            this.error = error.body.message;
            this.cases = undefined;
        }
    }
    @wire(getPortalUserCases)
wiredCases({ error, data }) {
    if (data) {
        console.log('✅ Cases ontvangen:', JSON.stringify(data, null, 2)); // Log cases
        this.cases = data;
        this.error = undefined;
    } else if (error) {
        console.error('❌ Fout bij ophalen cases:', error);
        this.error = error.body.message;
        this.cases = undefined;
    }
}
}