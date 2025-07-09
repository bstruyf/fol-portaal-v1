import { LightningElement, api, wire } from 'lwc';
import getActiveViewers from '@salesforce/apex/CaseViewerController.getActiveViewers';
import registerViewer from '@salesforce/apex/CaseViewerController.registerViewer';
import unregisterViewer from '@salesforce/apex/CaseViewerController.unregisterViewer';

export default class CaseViewerWarningV2 extends LightningElement {
    _recordId;
    _renderedOnce = false;

    @api
    set recordId(value) {
        this._recordId = value;
    }
    get recordId() {
        return this._recordId;
    }

    viewerNameList = [];
    showWarning = false;

    renderedCallback() {
        if (this.recordId && !this._renderedOnce) {
            this._renderedOnce = true;
            registerViewer({ caseId: this.recordId });
        }
    }

    disconnectedCallback() {
        if (this.recordId) {
            unregisterViewer({ caseId: this.recordId });
        }
    }

    @wire(getActiveViewers, { caseId: '$recordId' })
    wiredViewers({ data, error }) {
        if (data) {
            this.viewerNameList = data;
            this.showWarning = data.length > 0;
        } else {
            console.error('❌ Fout bij ophalen actieve viewers:', error);
            this.viewerNameList = [];
            this.showWarning = false;
        }
    }

    get viewerNamesJoined() {
        return this.viewerNameList.join(', ');
    }
}