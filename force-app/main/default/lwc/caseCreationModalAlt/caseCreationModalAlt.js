import { LightningElement, api, track } from 'lwc';
import searchArticles from '@salesforce/apex/CaseSupportController.searchArticles';
import getSimilarCases from '@salesforce/apex/CaseSupportController.getSimilarCases';

export default class CaseCreationModalAlt extends LightningElement {
  @api caseId;
  @track showModal = true;
  @track searchTerm = '';
  @track knowledgeArticles = [];
  @track similarCases = [];

  columns = [
    { label: 'Meldingnummer', fieldName: 'CaseNumber', type: 'text' },
    { label: 'Onderwerp', fieldName: 'Subject', type: 'text' },
    { label: 'Status', fieldName: 'Status', type: 'text' }
  ];

  connectedCallback() {
    if (!this.caseId) return;
    getSimilarCases({ caseId: this.caseId }).then(data => {
      this.similarCases = data;
    }).catch(error => {
      console.error('❌ Fout bij ophalen vergelijkbare cases:', error);
    });
  }

  handleSearchChange(event) {
    this.searchTerm = event.detail.value;
    if (this.searchTerm && this.searchTerm.length >= 3) {
      searchArticles({ searchTerm: this.searchTerm }).then(result => {
        this.knowledgeArticles = result;
      }).catch(error => {
        console.error('❌ Fout bij kennisartikelen:', error);
      });
    } else {
      this.knowledgeArticles = [];
    }
  }

  handleClose() {
    this.showModal = false;
  }
}