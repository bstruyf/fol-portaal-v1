import { LightningElement, api } from 'lwc';
import uploadFile from '@salesforce/apex/FilePasteUploaderController.uploadFile';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class FileUploadAction extends LightningElement {
    @api recordId; // Case ID ontvangen vanuit de Flow
    @api pendingFiles; // Bestanden als JSON-string

    connectedCallback() {
        if (this.recordId && this.pendingFiles) {
            try {
                const filesArray = JSON.parse(this.pendingFiles); // Zet JSON-string om naar array
                this.uploadFiles(filesArray);
            } catch (error) {
                console.error('Fout bij parsen van JSON:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Fout',
                        message: 'Bestandsgegevens konden niet worden geladen.',
                        variant: 'error'
                    })
                );
            }
        }
    }

    uploadFiles(filesArray) {
        filesArray.forEach(file => {
            uploadFile({ fileName: file.fileName, base64Data: file.base64Data, recordId: this.recordId })
                .then(() => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Succes',
                            message: `${file.fileName} geüpload naar de Case`,
                            variant: 'success'
                        })
                    );
                })
                .catch(error => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Fout',
                            message: error.body.message,
                            variant: 'error'
                        })
                    );
                });
        });
    }
}