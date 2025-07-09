import { LightningElement, track, wire } from 'lwc';
import { CurrentPageReference }            from 'lightning/navigation';
import createFeedItem                     from '@salesforce/apex/CasePostCommentController.createFeedItem';
import { ShowToastEvent }                 from 'lightning/platformShowToastEvent';

export default class CasePostComment extends LightningElement {
    @track title     = 'Update Apotheekteam';
    @track body      = '';
    @track isPosting = false;
    recordId;

    // Haal de Case-Id uit de URL
    @wire(CurrentPageReference)
    getStateParameters(cpr) {
        if (cpr) {
            const { attributes, state } = cpr;
            this.recordId = attributes.recordId || state.c__recordId;
        }
    }

    handleTitleChange(evt) {
        this.title = evt.detail.value;
    }
    handleBodyChange(evt) {
        this.body = evt.detail.value;
    }
    handleCancel() {
        this.title = 'Update Apotheekteam';
        this.body  = '';
    }

    postComment() {
        const text  = this.body.trim();
        const title = this.title.trim();
        if (!this.recordId || !text) {
            this.showToast('Fout', 'RecordId en bericht zijn verplicht.', 'error');
            return;
        }
        this.isPosting = true;
        createFeedItem({ recordId: this.recordId, title, body: text })
            .then(() => {
                this.showToast('Succes', 'Opmerking succesvol geplaatst.', 'success');
                this.body = '';
                this.dispatchEvent(new CustomEvent('refreshfeed'));
            })
            .catch(error => {
                this.showToast(
                    'Fout bij plaatsen',
                    error.body?.message || error.message,
                    'error'
                );
            })
            .finally(() => {
                this.isPosting = false;
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}