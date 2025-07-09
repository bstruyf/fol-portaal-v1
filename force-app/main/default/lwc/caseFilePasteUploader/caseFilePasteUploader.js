import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import uploadFileToCaseAndReturnDistributionId from '@salesforce/apex/CaseFileUploaderController.uploadFileToCaseAndReturnDistributionId';
import getDistributionUrl from '@salesforce/apex/CaseFileUploaderController.getDistributionUrl';

export default class CaseFilePasteUploader extends LightningElement {
    @api recordId;
    @track fileName = '';
    @track fileBase64 = '';
    @track isSuccess = false;
    @track error = false;
    @track downloadUrl = '';


    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.attributes.recordId;
        }
    }

    handleDragOver(event) {
        event.preventDefault();
    }

    handleDrop(event) {
        event.preventDefault();
        const files = event.dataTransfer.files;
        if (files?.length) {
            this.processFile(files[0]);
        }
    }

    handlePaste(event) {
        const items = event.clipboardData?.items;
        if (items) {
            for (let item of items) {
                if (item.kind === 'file') {
                    this.processFile(item.getAsFile());
                    break;
                }
            }
        }
    }

    processFile(file) {
        const now = new Date();
        const pad = n => String(n).padStart(2, '0');
        const datePart = `${now.getFullYear()}${pad(now.getMonth()+1)}${pad(now.getDate())}`;
        const timePart = `${pad(now.getHours())}${pad(now.getMinutes())}${pad(now.getSeconds())}`;

        let ext = '';
        if (file.name?.includes('.')) {
            ext = file.name.slice(file.name.lastIndexOf('.'));
        } else if (file.type) {
            const m = file.type.match(/\/(png|jpe?g|gif|bmp)$/);
            ext = m ? `.${m[1] === 'jpeg' ? 'jpg' : m[1]}` : '';
        }
        this.fileName = `screenshot_${datePart}_${timePart}${ext}`;

        const reader = new FileReader();
        reader.onloadend = () => {
            this.fileBase64 = reader.result.split(',')[1];
        };
        reader.readAsDataURL(file);
    }

    handleAddFileToCase() {
        this.isSuccess = false;
        this.error = false;

        if (!this.fileName || !this.fileBase64) {
            this.error = true;
            return;
        }

        uploadFileToCaseAndReturnDistributionId({
        caseId: this.recordId,
        base64Content: this.fileBase64,
        fileName: this.fileName
    })
    .then((distId) => {
        console.log('[Upload] Upload voltooid. DistributionId:', distId);

        // wacht 5 seconden om distributie-URL op te halen
        setTimeout(() => {
            getDistributionUrl({ distributionId: distId })
                .then((url) => {
                    console.log('[Upload] Distributie-URL opgehaald:', url);
                    if (url) {
                        this.isSuccess = true;
                        this.downloadUrl = url;

                        setTimeout(() => {
                            console.log('[Upload] Reset na 3s');
                            this.fileName = '';
                            this.fileBase64 = '';
                            this.isSuccess = false;
                            this.downloadUrl = '';
                        }, 3000);
                    } else {
                        console.warn('[Upload] Geen publieke URL beschikbaar (nog null)');
                        this.error = true;
                    }
                })
                .catch((err) => {
                    console.error('[Upload] Fout bij ophalen distributie-URL:', err);
                    this.error = true;
                });
        }, 3000); // wacht 5 sec
    })
    .catch((err) => {
        console.error('[Upload] Fout bij upload:', err);
        this.error = true;
    });
}

    // getter voor disabled-state van de knop
    get disableAddButton() {
        return this.fileName === '';
    }
}