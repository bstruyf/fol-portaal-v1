// caseFeed.js
import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference }        from 'lightning/navigation';
import { getRecord, getFieldValue }   from 'lightning/uiRecordApi';
import getCaseFeed                     from '@salesforce/apex/CaseFeedController.getCaseFeed';
import CONTACT_ID_FIELD                from '@salesforce/schema/Case.ContactId';
import ANMELDER_NAME_FIELD             from '@salesforce/schema/Case.Aanmelder__r.Name';
import ANMELDER_ID_FIELD               from '@salesforce/schema/Case.Aanmelder__c';
import './caseFeed.css';

export default class CaseFeed extends LightningElement {
    @track feedItems       = [];
    recordId;
    recordContactId = '';
    caseAanmelder   = '';
    caseAanmelderId = '';
    error;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [CONTACT_ID_FIELD, ANMELDER_ID_FIELD, ANMELDER_NAME_FIELD]
    })
    wiredCase({ data, error }) {
        if (data) {
            this.recordContactId = getFieldValue(data, CONTACT_ID_FIELD)   || '';
            this.caseAanmelderId = getFieldValue(data, ANMELDER_ID_FIELD)   || '';
            this.caseAanmelder   = getFieldValue(data, ANMELDER_NAME_FIELD) || '';
        }
        if (error) {
            this.error = error;
        }
    }

    @wire(CurrentPageReference)
    setPageRef(pageRef) {
        if (pageRef?.attributes?.recordId) {
            this.recordId = pageRef.attributes.recordId;
        }
    }

    @wire(getCaseFeed, { caseId: '$recordId' })
    wiredFeed({ data, error }) {
        if (data) {
            this.error = undefined;
            this.feedItems = data
                .filter(item => ['CaseCreated','Chatter','Email','Taak','Afspraak','Bijlage']
                                 .includes(item.type))
                .map(item => {
                    const createdDate  = new Date(item.createdDate);
                    const isAttachment = item.type === 'Bijlage';
                    const isComment    = item.type === 'Chatter';
                    const isEmail      = item.type === 'Email';
                    const isCaseCreated = item.type === 'CaseCreated';  // <-- nieuwe vlag

                    // voor Chatter‐posts: commentBody (escape-html of trusted rich-text)
                    const commentBody = isComment
                        ? item.content
                        : null;
                    // voor e-mails: raw HTML injection
                    const htmlContent = isEmail
                        ? item.content
                        : null;
                    // voor CaseCreated: we willen niet plain text, maar een vaste zin
                    const plainContent = isCaseCreated
                        ? 'heeft deze melding ingediend'
                        : (!isAttachment && !isComment && !isEmail)
                            ? item.content
                            : null;

                    // label voor bijlage‐download
                    const linkLabel = isAttachment
                        ? (item.title && item.title.trim().length > 0
                            ? item.title
                            : 'Download bijlage')
                        : null;

                    return {
                        id:                   item.id,
                        type:                 item.type,
                        isAttachment,
                        isComment,
                        isEmail,
                        isCaseCreated,        // <-- new property
                        actorName:            item.actorName,
                        createdDateFormatted: this.formatDateTime(createdDate),
                        iconName:             this.getIconName(item.type),
                        prefixLine:           item.title,
                        downloadUrl: item.publicUrl
    ? item.publicUrl
    : (item.versionId
        ? `/sfc/servlet.shepherd/version/download/${item.versionId}`
        : null),
                        commentBody,
                        htmlContent,
                        plainContent,         // <-- eventueel gebruikt in template
                        linkLabel
                    };
                });

            // Alleen e‐mail HTML injecteren
            setTimeout(() => {
                this.feedItems.forEach(item => {
                    if (item.isEmail && item.htmlContent) {
                        const container = this.template.querySelector(
                            `div[data-id="${item.id}"]`
                        );
                        if (container) {
                            container.innerHTML = item.htmlContent;
                        }
                    }
                });
            }, 0);
        } else {
            this.error     = error;
            this.feedItems = [];
        }
    }

    getIconName(type) {
        switch (type) {
            case 'CaseCreated': return 'standard:case';
            case 'Chatter':     return 'standard:feed';
            case 'Email':       return 'standard:email';
            case 'Taak':        return 'standard:task';
            case 'Afspraak':    return 'standard:event';
            case 'Bijlage':     return 'standard:attachment';
            default:            return 'standard:record';
        }
    }

    formatDateTime(date) {
        return new Intl.DateTimeFormat('nl-BE', {
            day: '2-digit', month: '2-digit', year: 'numeric',
            hour: '2-digit', minute: '2-digit', hour12: false
        }).format(date);
    }
}