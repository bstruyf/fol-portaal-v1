import { LightningElement, api, wire } from 'lwc';
import getCurrentViewer from '@salesforce/apex/CaseViewerController.getCurrentViewer';

export default class CaseViewerWarning extends LightningElement {
    @api recordId;
    viewerName = '';
    showWarning = false;

    @wire(getCurrentViewer, { caseId: '$recordId' })
    wiredViewer({ data, error }) {
        if (data) {
            this.showWarning = !data.isCurrentUser;
            this.viewerName = data.userName;
        } else if (error) {
            console.error('Error retrieving viewer:', error);
        }
    }
}