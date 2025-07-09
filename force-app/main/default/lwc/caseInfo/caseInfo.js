import { LightningElement, wire, api, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getCaseInfo from '@salesforce/apex/CaseInfoController.getCaseInfo';
import getCaseFiles from '@salesforce/apex/CaseInfoController.getCaseFiles';

export default class CaseInfo extends LightningElement {
    @api recordId;
    @track hoveredUrl = '';
@track isPreviewVisible = false;
    caseData;
    error;

    // Nu houden we een lijst van FileWrapper-objects bij (title + downloadUrl)
    files;
    filesError;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference && !this.recordId) {
            this.recordId = currentPageReference.attributes?.recordId;
            console.log('📌 Gevonden recordId:', this.recordId);
        }
    }

    @wire(getCaseInfo, { caseId: '$recordId' })
    wiredCase({ data, error }) {
        if (!this.recordId) {
            console.warn('⚠️ wire skipped, recordId is nog undefined');
            return;
        }
        if (data) {
            this.caseData = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.caseData = undefined;
        }
    }

    // **Nieuwe wire**: haalt FileWrapper-lijst op
    @wire(getCaseFiles, { caseId: '$recordId' })
    wiredFiles({ data, error }) {
        if (data) {
            // "data" is hier al een array van FileWrapper-objecten met twee properties: { title, downloadUrl }
            this.files = data;
            this.filesError = undefined;
        } else if (error) {
            console.error('❌ Fout bij ophalen files via Apex:', JSON.stringify(error));
            this.filesError = error;
            this.files = undefined;
        }
    }

    get createdDate() {
        return this.formatDate(this.caseData?.CreatedDate);
    }

    get streefdatum() {
        return this.formatDate(this.caseData?.Date_Time_target__c);
    }

    get aanmelder() {
        return this.caseData?.Aanmelder__r?.Name || '';
    }

    get behandelaar() {
    const owner = this.caseData?.Owner;
    if (!owner) return '';
    if (owner.Type === 'Queue') return `${owner.Name} (groep)`;
    return `${owner.FirstName} ${owner.LastName}`;
}

    formatDate(value) {
        return value ? new Date(value).toLocaleDateString() : '';
    }
    showPreview(event) {
    this.hoveredUrl = event.currentTarget.dataset.url;
    this.isPreviewVisible = true;
}

hidePreview() {
    this.hoveredUrl = '';
    this.isPreviewVisible = false;
}
}