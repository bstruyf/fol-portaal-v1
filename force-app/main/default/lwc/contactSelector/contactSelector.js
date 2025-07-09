import { LightningElement, api, track } from 'lwc';
import getContactRelations from '@salesforce/apex/ContactSelectorController.getContactRelations';

export default class ContactSelector extends LightningElement {
  @track _accountId;
  @api selectedContactId;
  @track contactOptions = [];
  @track showNewFields = false;
  debug = true;

  newFirstName = '';
  newLastName = '';
  newEmail = '';

  @api
  set accountId(value) {
    this._accountId = value;
    if (value) {
      this.loadContacts(value);
    }
  }

  get accountId() {
    return this._accountId;
  }

  loadContacts(accountId) {
    getContactRelations({ accountId })
      .then(data => {
        const filtered = data
  .filter(c => c.firstName && c.firstName.trim() !== '')
  .map(c => {
    const roleLabel = c.role && c.role.trim() !== '' ? c.role.split(';').join(', ') : 'geen rol';
    return {
      label: `${c.firstName} ${c.lastName} (${roleLabel})`,
      value: c.contactId,
      role: c.role
    };
  });

       this.contactOptions = [
  ...filtered,
  { label: 'Contactpersoon onbekend', value: 'onbekend' },
  { label: 'Nieuwe contactpersoon toevoegen', value: 'nieuw' }
];

// Stel standaardwaarde in indien Owner bestaat
const owner = filtered.find(c => c.role && c.role.includes('Owner'));
if (owner) {
  this.selectedContactId = owner.value;
  this.dispatchEvent(new CustomEvent('contactselected', {
    detail: {
      contactId: owner.value,
      isNew: false,
      fallbackOwnerId: false
    }
  }));
}
      })
      .catch(error => {
        console.error('Fout bij ophalen contacten:', error);
        this.contactOptions = [
          { label: '(Contactpersoon onbekend)', value: 'onbekend' },
          { label: '(Nieuwe contactpersoon toevoegen)', value: 'nieuw' }
        ];
      });
  }

  handleChange(event) {
    const value = event.detail.value;
    this.selectedContactId = value;
    this.showNewFields = value === 'nieuw';

    this.dispatchEvent(new CustomEvent('contactselected', {
      detail: {
        contactId: value,
        isNew: value === 'nieuw',
        fallbackOwnerId: value === 'onbekend'
      }
    }));
  }

  handleNewFirstName(event) {
    this.newFirstName = event.detail.value;
  }

  handleNewLastName(event) {
    this.newLastName = event.detail.value;
  }

  handleNewEmail(event) {
    this.newEmail = event.detail.value;
  }
}