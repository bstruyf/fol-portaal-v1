import { LightningElement, track } from 'lwc';
import getAllCategories from '@salesforce/apex/CategoryService.getAllCategories';

export default class CategorySubcategoryDropdown extends LightningElement {
  @track selectedCategory = '';
  @track selectedSubCategory = '';
  @track selectedCategoryId = '';
  @track categoryOptions = [];
  @track filteredSubCategoryOptions = [];
  @track debugInfo = [];

  allData = [];

  logDebug(message) {
    console.log(message);
    this.debugInfo = [...this.debugInfo, message];
  }

  connectedCallback() {
  this.debugInfo = ['Component gestart'];

  getAllCategories()
    .then(data => {
      this.debugInfo.push('Categorieën ontvangen: ' + JSON.stringify(data));
      this.allData = data;
      this.categoryOptions = data.map(cat => ({
        label: cat.category,
        value: cat.category
      }));
      this.debugInfo.push('Categorie-opties gegenereerd');
    })
    .catch(error => {
      this.debugInfo.push('FOUT bij ophalen categorieën: ' + JSON.stringify(error));
      this.categoryOptions = [
        { label: 'FallbackCat A', value: 'A' },
        { label: 'FallbackCat B', value: 'B' }
      ];
      this.filteredSubCategoryOptions = [
        { label: 'FallbackSub A1', value: 'A1' },
        { label: 'FallbackSub B1', value: 'B1' }
      ];
      this.debugInfo.push('Fallbackcategorieën geladen');
    });
}

  handleCategoryChange(event) {
    this.selectedCategory = event.detail.value;
    this.logDebug('Geselecteerde categorie: ' + this.selectedCategory);

    const match = this.allData.find(cat => cat.category === this.selectedCategory);
    if (match) {
      this.filteredSubCategoryOptions = match.subcategories.map(sub => ({
        label: sub.subcategory,
        value: sub.subcategory
      }));
      this.selectedSubCategory = '';
      this.selectedCategoryId = '';
      this.logDebug('Subcategorieën geladen: ' + JSON.stringify(this.filteredSubCategoryOptions));
    }
  }

  handleSubCategoryChange(event) {
    this.selectedSubCategory = event.detail.value;
    this.logDebug('Geselecteerde subcategorie: ' + this.selectedSubCategory);

    const cat = this.allData.find(c => c.category === this.selectedCategory);
    if (cat) {
      const sub = cat.subcategories.find(s => s.subcategory === this.selectedSubCategory);
      if (sub) {
        this.selectedCategoryId = sub.id;
        this.logDebug('Bijhorende ID gevonden: ' + this.selectedCategoryId);
      }
    }
  }
}