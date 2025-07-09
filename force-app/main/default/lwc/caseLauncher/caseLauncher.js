import { LightningElement, track } from 'lwc';
import getSoortMeldingValues from '@salesforce/apex/CaseLauncherController.getSoortMeldingValues';
import getSoortBinnenkomstValues from '@salesforce/apex/CaseLauncherController.getSoortBinnenkomstValues';
import getBehandelaarsgroepValues from '@salesforce/apex/CaseLauncherController.getBehandelaarsgroepValues';
import getRecentCases from '@salesforce/apex/CaseLauncherController.getRecentCases';
import getCaseFeed from '@salesforce/apex/CaseLauncherController.getCaseFeed';
import logCaseLaunch from '@salesforce/apex/CaseLauncherController.logCaseLaunch';
import setCaseInProgress from '@salesforce/apex/CaseLauncherController.setCaseInProgress';
import notifyOwnerOnReopen from '@salesforce/apex/CaseLauncherController.notifyOwnerOnReopen';
import createNewCase from '@salesforce/apex/CaseLauncherController.createNewCase';
import { NavigationMixin } from 'lightning/navigation';
import getApotheekteamEmail from '@salesforce/apex/CaseLauncherController.getApotheekteamEmail';
import getContactEmail from '@salesforce/apex/CaseLauncherController.getContactEmail';
import updateContactEmail from '@salesforce/apex/CaseLauncherController.updateContactEmail';
import searchSimilarCases from '@salesforce/apex/CaseLauncherController.searchSimilarCases';
import getEmailMessagesForCase from '@salesforce/apex/CaseLauncherController.getEmailMessagesForCase';
import suggestKnowledgeArticles from '@salesforce/apex/CaseLauncherController.suggestKnowledgeArticles';
import getStatusValues from '@salesforce/apex/CaseLauncherController.getStatusValues';
import getPriorityValues from '@salesforce/apex/CaseLauncherController.getPriorityValues';
import getCategoryAndSubcategoryOptions from '@salesforce/apex/CaseLauncherController.getCategoryAndSubcategoryOptions';
import createContact from '@salesforce/apex/CaseLauncherController.createContact';
import ContactId from '@salesforce/schema/Case.ContactId';

export default class CaseLauncher extends NavigationMixin(LightningElement) {
  @track selectedAccountId;
  @track selectedContactId;
  @track selectedSoortMelding = 'Incident';
  @track aantekeningen = '';
  @track soortMeldingOptions = [];
  @track recentCases = [];
  @track hoveredCase = null;
  @track hoveredFeed = [];
  @track logMessages = [];
  @track apotheekEmail = '';
  @track selectedContactEmail = '';
  @track mailToGeneralEmail = true;
  @track mailToAanmelder = false;
  @track showEmailInput = false;
  @track contactEmailDraft = '';
  @track globalSearchResults = [];
  @track emailFeed = [];
  @track selectedCaseDescription = '';
  @track suggestedArticles = [];
  @track caseActie = '';
  @track showCaseForm = false;
   @track statusOptions = [];
@track behandelaarsgroepOptions = 'FOL ContactDesk';;
@track priorityOptions = [];
@track soortBinnenkomstOptions = [];
@track categoryOptions = [];
@track subcategoryOptions = [];
categoryToSubMap = {};
@track isLoadingEmail = false;
newContactDetails = { firstName: '', lastName: '' };
@track draftCase = {
  Subject: '',
  Soort_Binnenkomst__c : '',
  Soort_Melding__c: '',
  Priority: '',
  Impact__c: '',
  Urgency__c: '',
  Date_Time_Target__c: null,
  Behandelaarsgroep__c: '',
  Status: '',
  Description: '',
  Description2__c: '',
  Category__c: '',
  Subcategory__c: '',
};


  globalSearchColumns = [
    {
      type: 'button-icon',
      initialWidth: 40,
      cellAttributes: { alignment: 'center' },
      typeAttributes: {
        iconName: 'utility:preview',
        name: 'viewEmails',
        alternativeText: 'Bekijk e-mails',
        title: 'Bekijk e-mails'
      }
    },
    {
      label: 'Meldingnummer',
      fieldName: 'caseUrl',
      type: 'url',
      typeAttributes: { label: { fieldName: 'CaseNumber' }, target: '_blank' },
      sortable: true,
      initialWidth: 130
    },
    { label: 'Korte Omschrijving', fieldName: 'Subject' },
    { label: 'Categorie', fieldName: 'Category__c' },
    { label: 'Subcategorie', fieldName: 'Subcategory__c' },
    { label: 'Status', fieldName: 'Status' },
    { label: 'Aanmelddatum', fieldName: 'createdFormatted' }
  ];

  columns = [
    {
      type: 'button-icon',
      initialWidth: 40,
      cellAttributes: { alignment: 'center' },
      typeAttributes: {
        iconName: 'utility:preview',
        name: 'viewEmails',
        alternativeText: 'Bekijk e-mails',
        title: 'Bekijk e-mails'
      }
    },
    {
      label: 'Meldingnummer',
      fieldName: 'caseUrl',
      type: 'url',
      typeAttributes: { label: { fieldName: 'CaseNumber' }, target: '_blank' },
      sortable: true,
      initialWidth: 130
    },
    {
      type: 'button-icon',
      initialWidth: 16,
      cellAttributes: { style: 'padding: 0; width: 16px; text-align: center;' },
      typeAttributes: {
        iconName: 'utility:arrowdown',
        name: 'navigateCase',
        alternativeText: 'Ga naar case',
        title: 'Ga naar case'
      }
    },
    { label: 'Type', fieldName: 'Record_Type__c' },
    { label: 'Aanmelder', fieldName: 'AanmelderName' },
    { label: 'Korte Omschrijving', fieldName: 'Subject' },
    { label: 'Behandelaar', fieldName: 'OwnerName' },
    { label: 'Categorie', fieldName: 'Category__c' },
    { label: 'Subcategorie', fieldName: 'Subcategory__c' },
    { label: 'Status', fieldName: 'Status' },
    { label: 'Aanmelddatum', fieldName: 'createdFormatted' },
    { label: 'Datum Gereed', fieldName: 'closedFormatted' },
    { label: 'Streefdatum', fieldName: 'targetFormatted' },
    { label: 'Prioriteit', fieldName: 'Priority' }
  ];

  connectedCallback() {
  const redirectCaseId = sessionStorage.getItem('redirectToCase');
  if (redirectCaseId) {
    sessionStorage.removeItem('redirectToCase');
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: {
        recordId: redirectCaseId,
        objectApiName: 'Case',
        actionName: 'view'
      }
    });
    const shouldRefresh = sessionStorage.getItem('refreshLauncherOnNextVisit');
if (shouldRefresh === 'true') {
  sessionStorage.removeItem('refreshLauncherOnNextVisit');
  this.log('🔁 Pagina ververst na terugkomst');
  window.location.reload();
}

    return;
    
  }
    
getCategoryAndSubcategoryOptions()
  .then(data => {
    console.log('📦 Gekregen categorie/subcategorie data:', JSON.stringify(data, null, 2));
    this.allCategoryData = data;
    this.categoryOptions = data.map(d => ({ label: d.category, value: d.category }));

    this.categoryToSubMap = {};
    data.forEach(item => {
      console.log(`➡️ ${item.category} heeft subcategorieën:`, item.subcategories);
      this.categoryToSubMap[item.category] = item.subcategories.map(sub => ({
        label: sub,
        value: sub
      }));
      console.log('🔍 categoryToSubMap:', JSON.stringify(this.categoryToSubMap, null, 2));
    });
  })
  .catch(error => this.logError('Fout bij ophalen categorie/subcategorie', error));
  getSoortMeldingValues()
    .then(result => {
      this.soortMeldingOptions = result.map(val => ({
        label: val,
        value: val
      }));
    })
    .catch(error =>
      this.logError('Fout bij ophalen soort meldingen', error)
    );

getStatusValues()
  .then(result => {
    this.statusOptions = result.map(val => ({ label: val, value: val }));
  })
  .catch(error => this.logError('Fout bij ophalen statuswaarden', error));
  getSoortBinnenkomstValues()
    .then(result => {
      this.soortBinnenkomstOptions = result.map(val => ({ label: val, value: val }));

      // ✅ Zet default enkel als nog geen waarde staat
      if (!this.draftCase.Soort_Binnenkomst__c && this.soortBinnenkomstOptions.find(o => o.value === 'Telefonisch')) {
        this.draftCase.Soort_Binnenkomst__c = 'Telefonisch';
      }
    })
    .catch(error => this.logError('Fout bij ophalen soort binnenkomst', error));
getPriorityValues()
  .then(result => {
    this.priorityOptions = result.map(val => ({ label: val, value: val }));
    if (!this.draftCase.Priority) {
      this.draftCase.Priority = 'N/A';
    }
  })
  .catch(error => this.logError('Fout bij ophalen prioriteitswaarden', error));
  getBehandelaarsgroepValues()
    .then(result => {
      this.behandelaarsgroepOptions = result.map(val => ({ label: val, value: val }));
    })
    .catch(error => this.logError('Fout bij ophalen behandelaarsgroepwaarden', error));
}

  handleAccountSelected(event) {
    this.selectedAccountId = event.detail.accountId;
    if (this.selectedAccountId) {
      getRecentCases({ accountId: this.selectedAccountId })
        .then(data => {
          this.recentCases = data.map(c => ({
            Id: c.Id,
            CaseNumber: c.CaseNumber,
            Record_Type__c: c.Record_Type__c,
            AanmelderName: c.Aanmelder__r?.Name || '',
            OwnerName: c.Owner?.Name || '',
            Subject: c.Subject,
            Category__c: c.Category__c,
            Subcategory__c: c.Subcategory__c,
            Status: c.Status,
            createdFormatted: this.formatDate(c.CreatedDate),
            closedFormatted: this.formatDate(c.ClosedDate),
            targetFormatted: this.formatDate(c.Date_Time_target__c),
            Priority: c.Priority,
            caseUrl: `/lightning/r/Case/${c.Id}/view`
          }));
        })
        .catch(error => this.logError('Fout bij ophalen recente cases', error));

      getApotheekteamEmail({ accountId: this.selectedAccountId })
        .then(result => {
          this.apotheekEmail = result || '';
        })
        .catch(error => {
          this.apotheekEmail = '';
          this.logError('Fout bij ophalen Apotheekteam e-mailadres', error);
        });
    }
  }

  handleContactSelected(event) {
  const contactId = event.detail.contactId;

  // Skip als niets verandert
  if (contactId === this.selectedContactId) {
    this.logMessages.push(`⏭️ Zelfde contactId als vorige: ${contactId}`);
    return;
  }

  this.selectedContactId = contactId;
  this.selectedContactEmail = ''; // reset, wordt weer gezet bij geldige ID
  this.isLoadingEmail = false;

  // Geldige Salesforce Contact ID = 15+ tekens en begint met '003'
  const isValidId = contactId && contactId.startsWith('003') && contactId.length >= 15;

  this.logMessages.push(`✅ selectedContactId: ${this.selectedContactId}`);

  if (isValidId) {
    this.isLoadingEmail = true;
    getContactEmail({ contactId })
      .then(result => {
        this.selectedContactEmail = result || '';
        this.logMessages.push(`📧 selectedContactEmail: ${this.selectedContactEmail}`);
      })
      .catch(error => {
        this.logError('Fout bij ophalen e-mailadres van contactpersoon', error);
        this.selectedContactEmail = '';
      })
      .finally(() => {
        this.isLoadingEmail = false;
      });
  } else {
    this.logMessages.push(`📧 Geen geldig contactId voor ophalen e-mailadres`);
    this.selectedContactEmail = '';
  }
}

  handleAddEmailClick() {
    this.showEmailInput = true;
    this.contactEmailDraft = '';
  }

  handleEmailInputBlur(event) {
    const newEmail = event.target.value;
    if (!newEmail || !this.selectedContactId) return;

    updateContactEmail({ contactId: this.selectedContactId, email: newEmail })
      .then(() => {
        this.selectedContactEmail = newEmail;
        this.showEmailInput = false;
        this.log('✅ E-mailadres succesvol opgeslagen');
      })
      .catch(error => {
        this.logError('Fout bij opslaan e-mailadres', error);
      });
  }

  handleToggleMailToGeneralEmail(event) {
    this.mailToGeneralEmail = event.detail.checked;
  }

  handleToggleMailToAanmelder(event) {
    this.mailToAanmelder = event.detail.checked;
  }

  handleAantekeningChange(event) {
  this.aantekeningen = event.target.value;

    const plainText = (this.aantekeningen || '').replace(/<[^>]+>/g, '').trim();

if (plainText.length >= 3) {
    suggestKnowledgeArticles({ query: plainText })
        .then(result => {
            this.suggestedArticles = result.map(a => ({
  Id: a.Id,
  Title: a.Title,
  Environment: a.Environment__c,
  Cause: a.Cause__c,
  Problem: a.Problem__c,
  Answer: a.Answer__c,
  url: `/lightning/r/Knowledge__kav/${a.Id}/view`,
   showPopover: false // ✅ essentieel
}));

            console.log('KB Artikelen:', this.suggestedArticles);
        })
        .catch(error => {
            console.error('❌ Fout bij ophalen suggesties:', error);
            this.suggestedArticles = [];
        });
} else {
    this.suggestedArticles = [];
}
}

handleCreateCaseResolved() {
  this.showCaseForm = true;

  const htmlText = this.aantekeningen || '';
  const actieHtml = this.caseActie || '';

  const plainText = htmlText
  .replace(/<\/p>|<\/div>|<br\s*\/?>/gi, '\n') // br, div, p naar linebreaks
  .replace(/<[^>]*>/g, '') // alle andere HTML tags weg
  .replace(/\n\s*\n/g, '\n') // dubbele lege regels weg
  .trim();

  const firstLine = plainText.split('\n')[0] || 'Nieuw incident';

  this.draftCase = {
    Subject: firstLine,
    Soort_Binnenkomst__c: 'Telefonisch',
    Soort_Melding__c: 'Incident',
    Priority: 'N/A',
    Impact__c: 'None',
    Urgency__c: 'None',
    Date_Time_Target__c: null,
    Behandelaarsgroep__c: 'Farmad Online Contactdesk',
    Status: 'Closed',
    Description2__c: htmlText,
    OwnerName: 'Huidige gebruiker (wordt via Apex ingevuld)' // Alleen display
  };

  this.log('✅ Draft case ingevuld: ' + JSON.stringify(this.draftCase));
}

handleCreateCaseForwarded() {
  this.createCaseWithStatus('Doorgestuurd');
}
handleCreateCase() {
  if (!this.selectedAccountId || !this.aantekeningen) {
    alert('Selecteer een account en vul aantekeningen in.');
    return;
  }

  const payload = {
    accountId: this.selectedAccountId,
    contactId: this.selectedContactId,
    subject: this.draftCase.Subject,
    description: this.draftCase.Description,
    description2: this.draftCase.Description2__c,
    behandelaarsgroep: this.draftCase.Behandelaarsgroep__c,
    priority: this.draftCase.Priority,
    soortBinnenkomst: this.draftCase.Soort_Binnenkomst__c,
    soortMelding: this.draftCase.Soort_Melding__c,
    status: this.draftCase.Status,
    category: this.draftCase.Category__c,
    subcategory: this.draftCase.Subcategory__c
  };

  this.log('📤 Payload voor createNewCase: ' + JSON.stringify(payload));

  createNewCase(payload)
    .then(caseId => {
      this.log(`✅ Case aangemaakt met ID: ${caseId}`);
      sessionStorage.setItem('refreshLauncherOnNextVisit', 'true');
      sessionStorage.setItem('redirectToCase', caseId); // sla tijdelijk op
   // 🔁 direct navigeren na opslaan
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: {
        recordId: caseId,
        objectApiName: 'Case',
        actionName: 'view'
      }
    });
  })
  .catch(error => {
    this.logError('❌ Fout bij aanmaken case', error);
    alert('Fout bij aanmaken case (zie log).');
  });
}

  handleGlobalCaseSearch(event) {
    const term = event.target.value;
    if (!term || term.length < 3) {
      this.globalSearchResults = [];
      return;
    }

    searchSimilarCases({ searchTerm: term })
      .then(result => {
        this.globalSearchResults = result.map(c => ({
          Id: c.Id,
          CaseNumber: c.CaseNumber,
          Subject: c.Subject,
          Category__c: c.Category__c,
          Subcategory__c: c.Subcategory__c,
          Status: c.Status,
          createdFormatted: this.formatDate(c.CreatedDate),
          caseUrl: `/lightning/r/Case/${c.Id}/view`
        }));
      })
      .catch(error => this.logError('Fout bij globale case zoekopdracht', error));
  }

  handleGlobalResultAction(event) {
  const action = event.detail.action.name;
  const row = event.detail.row;
  console.log('👉 Global action triggered for case:', row);

  if (action === 'viewEmails') {
    this.selectedCaseDescription = row.Description2__c || '(geen beschrijving)';
this.log(`📌 Beschrijving geselecteerde case: ${this.selectedCaseDescription}`);

    getEmailMessagesForCase({ caseId: row.Id })
  .then(result => {
    this.emailFeed = result.map(e => ({
      Id: e.Id,
      subject: e.Subject,
      sender: e.FromAddress,
      toAddresses: e.ToAddress,
      createdFormatted: this.formatDate(e.CreatedDate),
      htmlContent: e.HtmlBody || '<i>(Geen inhoud)</i>'
    }));
    this.log(`📬 ${this.emailFeed.length} e-mails geladen`);
  })
  .catch(error => this.logError('Fout bij ophalen e-mails van case', error));
  }
}

  handleRowAction(event) {
    const actionName = event.detail.action.name;
    const row = event.detail.row;
    const caseId = row.Id;

    if (actionName === 'navigateCase') {
      const wasClosed = row.Status === 'Closed';

      Promise.all([
        setCaseInProgress({ caseId }),
        logCaseLaunch({
          caseId,
          contactId: this.selectedContactId,
          aantekeningen: this.aantekeningen,
          soortBinnenkomst: this.selectedSoortBinnenkomst
        })
      ])
        .then(() => {
          if (wasClosed) {
            return notifyOwnerOnReopen({
              caseId,
              caseNumber: row.CaseNumber,
              shortDescription: row.Subject,
              contactReopenedId: this.selectedContactId
            }).then(() => {
              window.open(`/lightning/r/Case/${caseId}/view`, '_blank');
            });
          } else {
            window.open(`/lightning/r/Case/${caseId}/view`, '_blank');
          }
        })
        .catch(error => this.logError('Fout tijdens row action', error));
    }
  }

  handleRowHover(event) {
    const caseId = event.detail?.row?.Id || event.currentTarget.dataset.id;
    const hovered = this.recentCases.find(c => c.Id === caseId);
    this.hoveredCase = hovered;

    if (hovered) {
      getCaseFeed({ caseId: hovered.Id })
        .then(result => {
          this.hoveredFeed = result.map(f => ({
            ...f,
            createdFormatted: this.formatDate(f.CreatedDate),
            creatorName: (f.CreatedBy && f.CreatedBy.Name) || 'Onbekend',
            messageBody: f.Body || '(leeg)'
          }))
        })
        .catch(error => this.logError('Fout bij ophalen case feed', error));
    }
  }
renderedCallback() {
  if (this.emailFeed && this.emailFeed.length) {
    this.emailFeed.forEach(mail => {
      const container = this.template.querySelector(`div.email-html[key="${mail.Id}"]`);
      if (container) {
        container.innerHTML = mail.htmlContent;
        this.log(`✅ HTML geplaatst voor e-mail ${mail.Id}`);
      } else {
        this.log(`⚠️ Geen container gevonden voor e-mail ${mail.Id}`);
      }
    });
  }
}
  formatDate(dateStr) {
    if (!dateStr) return '';
    const d = new Date(dateStr);
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')} ${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
  }

  log(message) {
    const timestamp = new Date().toISOString();
    const line = `${timestamp} - ${message}`;
    this.logMessages = [...this.logMessages, line];
    console.log(line);
  }

  logError(context, error) {
    const raw = JSON.stringify(error);
    const msg = error?.body?.message || raw;
    this.log(`❌ ${context}: ${msg}`);
  }
get showEmailInputField() {
  this.logMessages.push(`✅ selectedContactId: ${this.selectedContactId}`);;
  this.logMessages.push(`📧 selectedContactEmail: ${this.selectedContactEmail}`);

 if (this.isLoadingEmail) return false;
  return (
    this.selectedContactId === 'Nieuwe contactpersoon toevoegen' ||
    (this.selectedContactId && !this.selectedContactEmail)
  );

  return isNewContact || isExistingWithoutEmail;
}
  get joinedReversedLog() {
    return this.logMessages.slice().reverse().join('\n');
  }

  get hasRecentCases() {
    return this.recentCases && this.recentCases.length > 0;
  }

  get hasFeed() {
    return this.hoveredFeed && this.hoveredFeed.length > 0;
  
}

keepPopover() {
    clearTimeout(this.popoverTimeout);
}

handleInsertAnswer(event) {
    const antwoord = event.target.dataset.answer;
    this.caseActie = this.caseActie ? this.caseActie + '\n\n' + antwoord : antwoord;
}
handleMouseEnter(event) {
  const id = event.currentTarget.dataset.id;
  this.suggestedArticles = this.suggestedArticles.map(a => ({
    ...a,
    showPopover: a.Id === id
  }));
}

handleMouseLeave(event) {
  const id = event.currentTarget.dataset.id;
  this.suggestedArticles = this.suggestedArticles.map(a => ({
    ...a,
    showPopover: false
  }));
}
handleCaseActieChange(event) {
  this.caseActie = event.target.value;
}
handleCategoryChange(event) {
  const selected = event.detail.value;
  this.draftCase.Category__c = selected;

  // Subcategorie opties bijwerken
  this.subcategoryOptions = this.categoryToSubMap[selected] || [];

  // Reset subcategorie-waarde
  this.draftCase.Subcategory__c = '';
}

handleSubCategoryChange(event) {
  this.draftCase.Subcategory__c = event.detail.value;

}
handleDraftChange(event) {
  const field = event.target.dataset.field;
  const value = event.detail.value;

  if (field) {
    this.draftCase[field] = value;
  }
}
handleDraftEmailChange(event) {
  this.contactEmailDraft = event.target.value;
}

handleSaveContactEmail() {
  if (!this.contactEmailDraft) return;

  const isNewContact = !this.selectedContactId || this.selectedContactId === 'nieuw';

  if (isNewContact) {
    // Haal voornaam en achternaam op uit de contactselector child component
    const contactSelector = this.template.querySelector('c-contact-selector');
    const firstName = this.newContactDetails.firstName;
const lastName = this.newContactDetails.lastName;

    if (!firstName || !lastName) {
      this.log('❌ Voornaam en achternaam zijn verplicht voor nieuwe contactpersoon');
      return;
    }

    // Contact aanmaken
    createContact({
      firstName,
      lastName,
      email: this.contactEmailDraft,
      accountId: this.selectedAccountId
    })
      .then((newContactId) => {
        this.selectedContactId = newContactId;
        this.selectedContactEmail = this.contactEmailDraft;
        this.log('✅ Nieuw contact met e-mailadres aangemaakt');
      })
      .catch(error => {
        this.logError('❌ Fout bij aanmaken van contactpersoon', error);
      });
  } else {
    // E-mailadres van bestaand contact updaten
    updateContactEmail({
      contactId: this.selectedContactId,
      email: this.contactEmailDraft
    })
      .then(() => {
        this.selectedContactEmail = this.contactEmailDraft;
        this.log('✅ E-mailadres succesvol opgeslagen');
      })
      .catch(error => {
        this.logError('❌ Fout bij opslaan e-mailadres', error);
      });
  }
}
handleNewContactUpdate(event) {
  this.newContactDetails = {
    firstName: event.detail.firstName || '',
    lastName: event.detail.lastName || ''
  };
  this.log(`🆕 Nieuwe contactgegevens ontvangen: ${this.newContactDetails.firstName} ${this.newContactDetails.lastName}`);
}
}