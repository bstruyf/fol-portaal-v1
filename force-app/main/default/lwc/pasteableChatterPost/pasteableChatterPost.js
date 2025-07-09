import { LightningElement, api, track } from 'lwc';
import postRichFeed from '@salesforce/apex/PasteableChatterController.postRichFeed';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ChatterPost extends LightningElement {
    @api recordId;               // context record (bv. Account, Case), valt terug op de gebruiker in Apex
    @track htmlContent = '';     // de rich-text (incl. base64-afbeeldingen)

    handleInputChange(event) {
        // bij iedere wijziging in de editor updaten we onze htmlContent
        this.htmlContent = event.detail.value;
    }

    handlePaste(event) {
        // zodra er een plaatje uit het klembord komt, converteren we 'm naar base64 en voegen we een <img> toe
        const items = event.clipboardData ? event.clipboardData.items : [];
        let hasImage = false;
        for (let i = 0; i < items.length; i++) {
            const item = items[i];
            if (item.kind === 'file') {
                hasImage = true;
                const file = item.getAsFile();
                const reader = new FileReader();
                reader.onload = () => {
                    // appenden aan de bestaande content; de editor mirroren we via value binding
                    this.htmlContent += `<p><img src="${reader.result}" alt="Pasted Image"/></p>`;
                };
                reader.readAsDataURL(file);
            }
        }
        if (hasImage) {
            // voorkom dubbele insert van de browser
            event.preventDefault();
        }
    }

    handleShare() {
        postRichFeed({
            parentId: this.recordId,
            htmlBody: this.htmlContent
        })
        .then(() => {
            // succes
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Gedeeld',
                    message: 'Je bericht is geplaatst in de Chatter-feed.',
                    variant: 'success'
                })
            );
            // reset editor
            this.htmlContent = '';
        })
        .catch(error => {
            // foutmelding tonen
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Fout bij delen',
                    message: (error.body && error.body.message) || error.message,
                    variant: 'error'
                })
            );
        });
    }
}