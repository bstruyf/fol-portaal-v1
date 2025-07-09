import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import getRawAIResponse from '@salesforce/apex/OpenAISubcategorySuggester.getRawAIResponse';
import getSubToCategoryMap from '@salesforce/apex/CategoryMappingService.getSubToCategoryMap';
import getAllCategories from '@salesforce/apex/CategoryService.getAllCategories';

const FIELDS = ['Case.Description2__c', 'Case.Hcategorie__c'];

export default class AiSubcategorySelector extends LightningElement {
  @api recordId;

  @track description = '';
  @track suggestions = [];
  @track error = '';
  @track selected = '';
  @track selectedCategory = '';
  @track selectedSubCategory = '';
  @track selectedCategoryId = '';
  @track categoryOptions = [];
  @track filteredSubCategoryOptions = [];
  @track debugInfo = [];

  subToCategoryMap = {};
  allData = [];
  _initialCategoryId;

  log(msg) {
    const tijd = new Date().toLocaleTimeString();
    this.debugInfo = [...this.debugInfo, `[${tijd}] ${msg}`];
    console.log(`[${tijd}] ${msg}`);
  }

  @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
wiredCase({ error, data }) {
  if (data) {
    this.description = data.fields.Description2__c.value;
    const linkedCategoryId = data.fields.Hcategorie__c?.value;
    this.log(`🧩 Gelinkte CategoryId op Case: ${linkedCategoryId}`);

    if (linkedCategoryId && this.allData.length > 0) {
      this.log('📌 AllData reeds beschikbaar, direct invullen');
      this.setSelectedCategoryFromId(linkedCategoryId);
    } else {
      this._initialCategoryId = linkedCategoryId;
      this.log(`⏳ Wacht op allData voor ID: ${linkedCategoryId}`);
    }

    // 🔥 Alleen automatisch suggestie als Hcategorie__c leeg is (nieuwe case)
    if (!linkedCategoryId && this.description) {
      this.log('⚡ Nieuwe case gedetecteerd → AI-suggestie gestart');
      this.handleGenerate();
    } else {
      this.log('🔁 Bestaande case → geen automatische suggestie');
    }

  } else if (error) {
    this.error = 'Fout bij ophalen case';
    this.log(`❌ Fout in wiredCase: ${JSON.stringify(error)}`);
  }
}

  connectedCallback() {
    this.log('🚀 Component geladen');

    getSubToCategoryMap()
      .then(map => {
        this.subToCategoryMap = map;
        this.log('✅ Sub→Category mapping opgehaald');
      })
      .catch(err => {
        this.error = 'Mapping ophalen mislukt.';
        this.log(`❌ Mapping error: ${JSON.stringify(err)}`);
      });

getAllCategories()
  .then(data => {
    this.allData = data;
    this.log('📦 Categoriegegevens opgehaald: ' + data.length);

    this.categoryOptions = data.map(cat => ({
      label: cat.category,
      value: cat.category
    }));

    if (this._initialCategoryId) {
      this.log(`📥 Init ID hergebruiken na ophalen categorieën: ${this._initialCategoryId}`);
      this.setSelectedCategoryFromId(this._initialCategoryId);
    }

    // ✅ AI-call enkel bij nieuwe case
    if (this._initialCategoryId === null && this.description) {
      this.log('🚨 Nieuwe case + allData beschikbaar → AI suggestie starten');
      this.handleGenerate();
    }
  })
  }

  setSelectedCategoryFromId(categoryId) {
    this.log(`🛠 Start setSelectedCategoryFromId met ID: ${categoryId}`);

    for (const cat of this.allData) {
      this.log(`🔎 Controleer categorie: ${cat.category}`);
      const match = cat.subcategories.find(sub => sub.id === categoryId);
      if (match) {
        this.log(`✅ Match gevonden → Cat: ${cat.category}, Sub: ${match.subcategory}`);

        this.selectedCategory = cat.category;
        this.selectedSubCategory = match.subcategory;
        this.selectedCategoryId = categoryId;

        this.filteredSubCategoryOptions = cat.subcategories.map(s => ({
          label: s.subcategory,
          value: s.subcategory
        }));

        this.log(`📋 selectedCategory: ${this.selectedCategory}`);
        this.log(`📋 selectedSubCategory: ${this.selectedSubCategory}`);
        this.log(`📋 filteredOptions: ${JSON.stringify(this.filteredSubCategoryOptions)}`);
        return;
      }
    }

    this.log(`❌ Geen match gevonden voor ID: ${categoryId}`);
  }

  handleGenerate() {
    this.suggestions = [];
    this.selected = '';
    this.error = '';

    getRawAIResponse({ description: this.description })
      .then((result) => {
        const raw = result.raw || '';
        this.suggestions = raw
          .split(',')
          .map(s => s.trim())
          .filter(s => s !== '');
        this.log('🤖 AI suggesties: ' + JSON.stringify(this.suggestions));
      })
      .catch((error) => {
        console.error('❌ Fout bij AI-call:', error);
        this.error = 'AI-call mislukt.';
        this.log(`❌ AI fout: ${JSON.stringify(error)}`);
      });
  }

  handleSelect(event) {
    const subcategory = event.target.dataset.value;
    const category = this.subToCategoryMap[subcategory];
    this.log(`🖱 Suggestie geklikt: ${subcategory} → ${category}`);

    if (!category) {
      this.error = `Geen hoofdcategorie gevonden voor subcategorie: ${subcategory}`;
      this.log(this.error);
      return;
    }

    const catMatch = this.allData.find(c => c.category === category);
    const subMatch = catMatch?.subcategories.find(s => s.subcategory === subcategory);

    if (!subMatch) {
      this.error = 'Category-record ID niet gevonden in cache';
      this.log(this.error);
      return;
    }

    const categoryId = subMatch.id;
    const fields = {
      Id: this.recordId,
      Hcategorie__c: categoryId,
      Category__c: category,
      Subcategory__c: subcategory
    };

    this.log(`📝 updateRecord met ID: ${categoryId}`);
    this.log(`➡️ Fields: ${JSON.stringify(fields)}`);

    updateRecord({ fields })
      .then(() => {
        this.selected = subcategory;
        this.error = '';
        this.log(`✅ Case opgeslagen`);
      })
      .catch(err => {
        this.error = 'Fout bij opslaan van de case';
        const msg = err?.body?.message || JSON.stringify(err);
        this.log(`❌ Fout bij updateRecord: ${msg}`);
        this.log(`🪵 Fields bij fout: ${JSON.stringify(fields)}`);
        console.error(err);
      });
  }

  handleCategoryChange(event) {
    this.selectedCategory = event.detail.value;
    this.log('📌 handmatige selectie categorie: ' + this.selectedCategory);

    const match = this.allData.find(cat => cat.category === this.selectedCategory);
    if (match) {
      this.filteredSubCategoryOptions = match.subcategories.map(sub => ({
        label: sub.subcategory,
        value: sub.subcategory
      }));
      this.selectedSubCategory = '';
      this.selectedCategoryId = '';
      this.log(`📋 subcategorieën vernieuwd (${this.filteredSubCategoryOptions.length})`);
    }
  }

  handleSubCategoryChange(event) {
  this.selectedSubCategory = event.detail.value;
  const cat = this.allData.find(c => c.category === this.selectedCategory);
  if (cat) {
    const sub = cat.subcategories.find(s => s.subcategory === this.selectedSubCategory);
    if (sub) {
      this.selectedCategoryId = sub.id;

      const fields = {
        Id: this.recordId,
        Hcategorie__c: sub.id,
        Category__c: this.selectedCategory,
        Subcategory__c: sub.subcategory
      };

      this.log(`📝 updateRecord bij handmatige keuze`);
      this.log(`➡️ Fields: ${JSON.stringify(fields)}`);

      updateRecord({ fields })
        .then(() => {
          this.log(`✅ Case opgeslagen`);
          this.error = '';
        })
        .catch(err => {
          this.error = 'Fout bij opslaan van de case';
          this.log(`❌ Fout bij updateRecord: ${JSON.stringify(err)}`);
        });
    }
  }
}

  get hasSuggestions() {
    return this.suggestions.length > 0;
  }

  get isSubDisabled() {
    return this.filteredSubCategoryOptions.length === 0;
  }
}