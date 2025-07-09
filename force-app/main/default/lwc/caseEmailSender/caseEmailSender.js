import { LightningElement, api, wire, track } from 'lwc';
import getCaseData from '@salesforce/apex/CaseEmailController.getCaseData';
import sendCaseEmail from '@salesforce/apex/CaseEmailController.sendCaseEmail';
import createCaseEvent from '@salesforce/apex/CaseEmailController.createCaseEvent';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getQuickTexts from '@salesforce/apex/CaseEmailController.getQuickTexts';

export default class CaseEmailSender extends LightningElement {
    @api recordId;

    @track subject;
    @track toAddress;
    @track fromAddress;
    @track userSignature;
    @track aanhef;
    @track typedMessage = '';
    @track body = '';
    @track debugLog;
    @track eventSubject;
    @track eventStartDate;
    @track eventStartTime;
    @track eventEndDate;
    @track eventEndTime;
    @track eventWhoId;
    @track eventWhoName;
    @track debug = true;
    @track internalOnly = false;
    @track quickTexts = [];
@track showQuickTextModal = false;

    initialized = false;
    caseData;

    @wire(getCaseData, { caseId: '$recordId' })
    wiredCase({ data, error }) {
        if (data) {
            this.caseData = data;
            this.fromAddress = data.fromAddress;
            this.toAddress = data.toRecipients.join('; ');
            this.subject = `${data.accountName} - Farmad : update op je melding : ${data.shortDescription} (ref. ${data.caseNumber})`;

            if (!this.initialized) {
                const voornaam = data.aanmelderVoornaam;
                this.aanhef = `Beste ${voornaam},<br/><br/>`;
                this.userSignature = `
                    <br/><br/>
                    Met vriendelijke groeten,<br/>
                    ${data.userName}<br/>
                    ${data.userTitle ? data.userTitle + '<br/>' : ''}
                    ${data.userEmail}<br/>
                    ${data.userPhone || ''}
                `;
                this.updateBody();
                this.initialized = true;
            }

            const now = new Date();
            const pad = (v) => String(v).padStart(2, '0');
            const startDate = now.toISOString().slice(0, 10);
            const startHour = now.getHours() + 1;

            this.eventSubject = data.shortDescription;
            this.eventStartDate = startDate;
            this.eventStartTime = pad(startHour) + ':00';
            this.eventEndDate = startDate;
            this.eventEndTime = pad(startHour) + ':15';
            this.eventWhoId = data.aanmelderId;
            this.eventWhoName = data.aanmelderName;
        }

        if (error) {
            console.error(error);
        }
    }

    handleBodyChange(event) {
        this.typedMessage = event.detail.value;
        this.updateBody();
    }

    updateBody() {
        this.body = this.aanhef + this.typedMessage + this.userSignature;
    }

    handleShare() {
        this.sendEmailAndUpdateCase(false);
    }

    handleShareAndClose() {
        this.sendEmailAndUpdateCase(true);
    }

    sendEmailAndUpdateCase(closeCase) {
        let subjectToUse = this.subject;
        let plainBody = this.typedMessage;
        let fullBody;

        const vraagBlok = `
            <br/><br/>
            <div style="background:#f2f2f2; padding: 1em; border-radius: 5px;">
                <strong>Oorspronkelijke melding:</strong><br/>
                ${this.caseData.description2__c || '<i>Niet beschikbaar</i>'}
            </div>
        `;

        if (closeCase) {
            subjectToUse = `${this.caseData.accountName} – afsluitend antwoord op je melding: ${this.caseData.shortDescription} (ref. ${this.caseData.caseNumber})`;

            const afsluitParagraaf = `
                <br/><br/>
                We vertrouwen erop dat je vraag met bovenstaande informatie is beantwoord en sluiten de melding hierbij af.<br/>
Mocht dat toch niet het geval zijn, dan kun je via de portal een reactie toevoegen op deze case. <br/>
Gebruik de volgende link om de status en updates te bekijken en te reageren:<br/>
<a href=""https://farmad--sandbox2.sandbox.my.site.com/FOLPortaal/case/${this.recordId}" target="_blank">Bekijk en reageer in de portal</a><br/>
De melding wordt dan automatisch heropend en we nemen opnieuw contact met je op.
            `;

            fullBody = this.aanhef + this.typedMessage + afsluitParagraaf + vraagBlok + this.userSignature;
        } else {
            fullBody = this.aanhef + this.typedMessage + vraagBlok + this.userSignature;
        }

        this.debugLog =
            '✉️ SUBJECT TO SEND:\n' + subjectToUse + '\n\n' +
            '📨 BODY TO SEND:\n' + fullBody;

        sendCaseEmail({
            caseId: this.recordId,
            subject: subjectToUse,
            body: fullBody,
            feedMessage: plainBody,
            closeCase: closeCase,
            internalOnly: this.internalOnly // ✅ extra parameter
        })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Succes',
                    message: 'Je antwoord is succesvol via e-mail verzonden en toegevoegd aan de case-feed',
                    variant: 'success'
                }));
                this.typedMessage = '';
                window.setTimeout(() => {
        window.location.reload();
    }, 1500);
            })
            .catch(error => {
                console.error(error);
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Fout',
                    message: 'Fout bij verzenden e-mail.',
                    variant: 'error'
                }));
            });
    }

    handleInputChange(event) {
        const { name, value } = event.target;
        this[name] = value;

        if (name === 'eventStartDate') {
            this.eventEndDate = value;
        }

        if (name === 'eventStartTime') {
            const [h, m] = value.split(':').map(Number);
            let endMinutes = m + 15;
            let endHour = h;
            if (endMinutes >= 60) {
                endMinutes -= 60;
                endHour += 1;
            }
            const pad = (v) => String(v).padStart(2, '0');
            this.eventEndTime = `${pad(endHour)}:${pad(endMinutes)}`;
        }
    }

    handleAttendeeChange(event) {
        this.eventWhoId = event.detail.value;
    }

    handleCreateAppointment() {
        
        if (!this.eventWhoId || !this.eventSubject) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Incompleet',
                message: 'Vul een deelnemer en onderwerp in.',
                variant: 'warning'
            }));
            return;
        }

        createCaseEvent({
            caseId: this.recordId,
            subject: this.eventSubject,
            startDate: this.eventStartDate,
            startTime: this.eventStartTime,
            endDate: this.eventEndDate,
            endTime: this.eventEndTime,
            whoId: this.eventWhoId
        })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Afspraak ingepland',
                    message: 'Er is een afspraak gemaakt met de opgegeven deelnemer.',
                    variant: 'success'
                }));
            })
            .catch(error => {
                console.error(error);
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Fout',
                    message: 'Afspraak maken is mislukt.',
                    variant: 'error'
                }));
                console.log('🔍 Debug info:');
                console.log('Case ID:', this.recordId || '❌ Niet ingevuld');
                console.log('WhoId:', this.eventWhoId || '❌ Geen deelnemer');
                console.log('Start:', this.eventStartDate, this.eventStartTime);
                console.log('Einde:', this.eventEndDate, this.eventEndTime);
                console.log('Onderwerp:', this.eventSubject || '❌ Leeg');
            });
    }
    handleInternalOnlyToggle(event) {
    this.internalOnly = event.target.checked;
}
@track activeTab = 'mail';

get isMailTab() {
  return this.activeTab === 'mail';
}

handleTabChange(event) {
  this.activeTab = event.target.value;
}
connectedCallback() {
  getQuickTexts({ channel: 'Email' })
    .then(result => {
      this.quickTexts = result.map(qt => ({
        label: qt.Name,
        value: qt.Message
      }));
    })
    .catch(error => this.logError('❌ Fout bij ophalen Quick Texts', error));
}
handleQuickTextInsert(event) {
  const selectedText = event.detail.value;
  this.typedMessage += selectedText;
}
}