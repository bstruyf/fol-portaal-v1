import { LightningElement, api, wire } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';

const CASE_FIELDS = ['Case.AccountId'];

export default class CaseCompactView extends LightningElement {
  @api recordId;

  // AANMELDER
  accountId;

  // BESTAANDE VELDEN
  @api naam;
  @api taal;
  @api telefoon;
  @api email;

  @api type;
  @api reden;
  @api omschrijving;

  @api datum;
  @api tijdslot;

  @api status;
  @api oplossing;
  @api afgehandeldDoor;

  @wire(getRecord, { recordId: '$recordId', fields: CASE_FIELDS })
  wiredCase({ data, error }) {
    if (data) {
      this.accountId = data.fields.AccountId?.value;
    } else if (error) {
      console.error('Fout bij ophalen Case:', error);
    }
  }
handleSuccess(event) {
  console.log('Record succesvol opgeslagen', event.detail.id);
  // eventueel: toast tonen of refresh
}
  handleAccountSelected(event) {
    const selectedAccountId = event.detail;

    if (!selectedAccountId || selectedAccountId === this.accountId) return;

    updateRecord({
      fields: {
        Id: this.recordId,
        AccountId: selectedAccountId
      }
    })
      .then(() => {
        this.accountId = selectedAccountId;
        console.log('AccountId succesvol bijgewerkt');
      })
      .catch((error) => {
        console.error('Fout bij updaten van AccountId:', error);
      });
  }
}