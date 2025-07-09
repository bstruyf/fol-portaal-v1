// chatterPost2.js
import { LightningElement, api, track } from 'lwc';
import postRichText from '@salesforce/apex/ChatterPost2Controller.postRichText';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ChatterPost2 extends LightningElement {
    @api recordId;
    @track htmlContent = '';
    @track logMessages = [];

    /** Loghelper: toont in console en UI, nieuwste bovenaan */
    log(msg, level = 'log') {
        const ts = new Date().toLocaleTimeString();
        const entry = `${ts} | ${msg}`;
        this.logMessages = [entry, ...this.logMessages];
        console[level](`[chatterPost2] ${msg}`);
    }

    handleInputChange(event) {
        this.htmlContent = event.detail.value;
        this.log(`✍️ Input changed, length=${this.htmlContent?.length || 0}`);
    }

    async handleShare() {
        this.log('▶ handleShare START');
        const body = this.htmlContent || '';
        this.log(`📨 htmlContent for post, length=${body.length}`);

        try {
            this.log('⏳ Calling Apex postRichText...');
            await postRichText({ recordId: this.recordId, htmlBody: body });
            this.log('✅ postRichText succeeded');

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Succes',
                    message: 'Bericht succesvol gepost naar Chatter',
                    variant: 'success'
                })
            );
            this.htmlContent = '';
            this.log('🔁 htmlContent reset na post');
        } catch (error) {
            const msg =
                error.body?.message ||
                (Array.isArray(error.body)
                    ? error.body.map(e => e.message).join('; ')
                    : JSON.stringify(error));
            this.log(`❌ postRichText error: ${msg}`, 'error');

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Fout',
                    message: msg,
                    variant: 'error'
                })
            );
        } finally {
            this.log('◀ handleShare END');
        }
    }
}