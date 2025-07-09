import { LightningElement, api } from 'lwc';

export default class AanmelderForm extends LightningElement {
  @api contactId;

  handleSuccess(event) {
    const evt = new CustomEvent('recordupdated', {
      detail: { id: event.detail.id }
    });
    this.dispatchEvent(evt);
  }
}