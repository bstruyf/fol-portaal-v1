import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

const CASE_CATEGORY_LOOKUP = ['Case.Hcategorie__c'];

export default class CaseCategoryEditor extends LightningElement {
  @api recordId;
  categoryId;
categoryFields = ['Category_Name__c', 'Category__c', 'SubCategory__c']
  @wire(getRecord, { recordId: '$recordId', fields: CASE_CATEGORY_LOOKUP })
  wiredCase({ error, data }) {
    console.log('WiredCase triggered for Case recordId:', this.recordId);
    if (data) {
      console.log('Case data ontvangen:', JSON.stringify(data));
      const field = data.fields.Hcategorie__c;
      if (field && field.value) {
        this.categoryId = field.value;
        console.log('Gekoppelde categorie ID:', this.categoryId);
      } else {
        this.categoryId = null;
        console.warn('Geen waarde gevonden voor Case_Category__c');
      }
    } else if (error) {
      console.error('Fout bij ophalen Case:', error);
    }
  }

  handleSuccess() {
    console.log('Categoriegegevens succesvol opgeslagen');
  }
}