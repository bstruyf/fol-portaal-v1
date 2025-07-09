import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import uploadFile from '@salesforce/apex/FilePasteUploaderController.uploadFile';

export default class FilePasteUploader extends LightningElement {
    @track fileName = ''; // Enkel laatste bestandsnaam tonen
    @api fileIds = []; // ✅ Zorg ervoor dat dit een @api property is

    handlePaste(event) {
        const clipboardItems = event.clipboardData.items;
        for (let item of clipboardItems) {
            if (item.type.indexOf('image') !== -1) {
                const file = item.getAsFile();
                this.processFile(file, true);
            }
        }
    }

    handleDrop(event) {
        event.preventDefault();
        const files = event.dataTransfer.files;
        if (files.length > 0) {
            this.processFile(files[0], false);
        }
    }

    handleDragOver(event) {
        event.preventDefault();
    }

    processFile(file, isPasted) {
        if (!file) return;

        const reader = new FileReader();
        reader.onloadend = () => {
            const base64 = reader.result.split(',')[1];
            this.fileName = isPasted ? `screenshot_${Date.now()}.png` : file.name;

            console.log('📂 Bestand wordt geüpload:', this.fileName);

            // Bestand uploaden naar Salesforce
            uploadFile({ fileName: this.fileName, base64Data: base64 })
                .then((fileId) => {
                    console.log('✅ Geüploade bestand-ID:', fileId);

                    if (!fileId) {
                        console.error('❌ Geen bestand-ID ontvangen van Salesforce');
                        return;
                    }

                    // ✅ Bestand-ID opslaan in array en doorgeven aan Flow
                    this.fileIds = [...this.fileIds, fileId];

                    // ✅ Stuur bestand-ID's naar Flow
                    this.dispatchEvent(new CustomEvent('fileupload', { detail: { fileIds: this.fileIds } }));

                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Succes',
                            message: `Bestand ${this.fileName} succesvol geüpload.`,
                            variant: 'success'
                        })
                    );
                })
                .catch(error => {
                    console.error('❌ Upload fout:', error);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Fout',
                            message: error.body?.message || 'Er is iets misgegaan bij het uploaden',
                            variant: 'error'
                        })
                    );
                });
        };
        reader.readAsDataURL(file);
    }
}