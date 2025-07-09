import { LightningElement, api } from 'lwc';
import zoekAccounts from '@salesforce/apex/AccountSelectorController.zoekAccounts';

export default class AccountSelector extends LightningElement {
  @api inputMode;
  @api selectedAccount;

  searchKey = '';
  results = [];
  showDropdown = false;
  highlightedIndex = -1;
  timeout;

  handleSearchKeyChange(event) {
    this.searchKey = event.target.value;
    this.highlightedIndex = -1;

    if (this.searchKey.length >= 2) {
      clearTimeout(this.timeout);
      this.timeout = setTimeout(() => {
        zoekAccounts({ key: this.searchKey })
          .then(data => {
            this.results = data.map((acc, index) => ({
              ...acc,
              _selected: false,
              computedClass: 'slds-listbox__item'
            }));
            this.showDropdown = true;
          })
          .catch(error => {
            console.error('Fout bij ophalen accounts:', error);
            this.results = [];
            this.showDropdown = false;
          });
      }, 300);
    } else {
      this.results = [];
      this.showDropdown = false;
    }
  }

  handleKeyDown(event) {
    if (!this.showDropdown || !this.results.length) return;

    if (event.key === 'ArrowDown') {
      event.preventDefault();
      if (this.highlightedIndex < this.results.length - 1) {
        this.highlightedIndex++;
        this.updateHighlight();
      }
    } else if (event.key === 'ArrowUp') {
      event.preventDefault();
      if (this.highlightedIndex > 0) {
        this.highlightedIndex--;
        this.updateHighlight();
      }
    } else if (event.key === 'Enter') {
      event.preventDefault();
      if (this.highlightedIndex >= 0 && this.highlightedIndex < this.results.length) {
        const selected = this.results[this.highlightedIndex];
        this.selectAccount(selected);
      }
    }
  }

  updateHighlight() {
    this.results = this.results.map((acc, index) => {
      const isHighlighted = index === this.highlightedIndex;
      return {
        ...acc,
        _selected: isHighlighted,
        computedClass: `slds-listbox__item slds-listbox__option slds-listbox__option_entity${isHighlighted ? ' slds-has-focus' : ''}`
      };
    });
  }

  handleSelect(event) {
    const selectedId = event.currentTarget.dataset.id;
    const selected = this.results.find(r => r.Id === selectedId);
    this.selectAccount(selected);
  }

  selectAccount(selected) {
    this.searchKey = `${selected.Name} (${selected.APB_SCN_Number__c || ''}) - ${selected.BillingCity || ''}`;
    this.selectedAccount = selected.Id;
    this.showDropdown = false;

    this.dispatchEvent(new CustomEvent('accountselected', {
      detail: { accountId: selected.Id }
    }));
  }

  handleFocus() {
    if (this.results.length > 0) {
      this.showDropdown = true;
    }
  }

  handleBlur() {
    setTimeout(() => {
      this.showDropdown = false;
    }, 200);
  }
}