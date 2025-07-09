// chatterPost.js
import { LightningElement, api, track } from 'lwc';
import uploadImage from '@salesforce/apex/ChatterPostController.uploadImage';
import postRichText from '@salesforce/apex/ChatterPostController.postRichText';
import ensureDocumentIdForVersion from '@salesforce/apex/ChatterPostController.ensureDocumentIdForVersion';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ChatterPost extends LightningElement {
  @api recordId;
  @track htmlContent = '';
  @track logMessages = [];

  /** Helper: log naar console én UI */
  log(msg, level = 'debug') {
    const ts = new Date().toLocaleTimeString();
    this.logMessages = [, `${ts} | ${msg}`, ...this.logMessages];
    console[level](`[chatterPost] ${msg}`);
  }

  /** Input change → detecteer rtaImage refids en convert */
  async handleInputChange(evt) {
  this.log('▶ handleInputChange START');
  this.htmlContent = evt.detail.value;
  this.log(`HTMLContent updated, length=${this.htmlContent.length}`);

  const uploads = [];
  const rtaRe = /<img[^>]*src="[^"]*rtaImage\?refid=(0EM[0-9A-Za-z]{12,15})"[^>]*>/gi;
  let match;

  while ((match = rtaRe.exec(this.htmlContent)) !== null) {
    const fullTag = match[0];
    const versionId = match[1];
    this.log(`📌 Found pasted rtaImage versionId=${versionId}`);

    uploads.push(
      resolveAndReuploadVersion({ versionId })
        .then(docId => {
          this.htmlContent = this.htmlContent.replace(
            fullTag,
            `<img src="sfdc://${docId}" alt="converted-${docId}"/>`
          );
          this.log(`✅ rtaImage replaced with sfdc://${docId}`);
        })
        .catch(err => {
          this.log(`❌ Error resolving versionId ${versionId}: ${err.body?.message || err.message}`, 'error');
        })
    );
  }

  if (uploads.length > 0) {
    await Promise.all(uploads);
    const rte = this.template.querySelector('lightning-input-rich-text');
    if (rte) {
      rte.value = this.htmlContent;
      this.log('✅ RTE.value updated na rtaImage vervanging');
    }
    this.log('✅ All rtaImage conversions done');
  } else {
    this.log('ℹ️ Geen rtaImage refs gevonden');
  }

  this.log('◀ handleInputChange END');
}

  /** Share handler: converteert <img sfdc://...> naar {img:...} rich text placeholders */
  async handleShare() {
    this.log('▶ handleShare START');
    this.log(`htmlContent before conversion, (length=${this.htmlContent.length}): ${this.htmlContent}`);

    const body = this.htmlContent
      .replace(
        /<img\s+[^>]*src="sfdc:\/\/(069[0-9A-Za-z]{12,15})"[^>]*alt="([^"]*)"[^>]*>/gi,
        '{img:$1:$2}'
      )
      .replace(
        /<img\s+[^>]*src="sfdc:\/\/(069[0-9A-Za-z]{12,15})"[^>]*>/gi,
        '{img:$1:}'
      );

    this.log(`Prepared htmlBody for Apex (length=${body.length}): ${body}`);

    try {
      this.log('Calling postRichText Apex');
      await postRichText({ recordId: this.recordId, htmlBody: body });
      this.log('✅ postRichText succeeded');

      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Succes',
          message: 'Chatter-post geplaatst',
          variant: 'success'
        })
      );

      this.htmlContent = '';
      this.log('🔄 htmlContent reset na succesvolle post');
    } catch (error) {
      this.log(`❌ postRichText error: ${JSON.stringify(error)}`, 'error');
      const msg =
        error.body?.message ||
        (Array.isArray(error.body)
          ? error.body.map((e) => e.message).join('; ')
          : JSON.stringify(error));
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Fout bij posten',
          message: msg,
          variant: 'error'
        })
      );
    } finally {
      this.log('▶ handleShare END');
    }
  }
}