import { LightningModal } from 'lightning/modal';
import { api } from 'lwc';
import template from './caseCreationModal.html';

export default class CaseCreationModal extends LightningModal {
  @api caseId;

  connectedCallback() {
    console.log('✅ Modal geladen met caseId:', this.caseId);
  }

  handleClose() {
    this.close();
  }

  render() {
    return template;
  }
}