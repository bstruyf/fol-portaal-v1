import { LightningElement, api, track } from 'lwc';
import getGreetingPreference from '@salesforce/apex/ContactPreferenceHelper.getGreetingPreference';
import saveGreetingPreference from '@salesforce/apex/ContactPreferenceHelper.saveGreetingPreference';
import getContactFullName from '@salesforce/apex/ContactPreferenceHelper.getContactFullName';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class GreetingPreferenceSelector extends LightningElement {
    @api contactId;

    @track selectedValue = '';
    @track showSelector = false;
    @track greetingOptions = [];

    firstName = '';
    lastName = '';

    connectedCallback() {
        if (this.contactId) {
            getGreetingPreference({ contactId: this.contactId })
                .then(pref => {
                    if (!pref) {
                        this.showSelector = true;
                        getContactFullName({ contactId: this.contactId })
                            .then(result => {
                                const [first, last] = result.split('|');
                                this.firstName = first;
                                this.lastName = last;
                                this.setupOptions();
                            })
                            .catch(error => {
                                console.error('⚠️ Fout bij ophalen naam:', error);
                            });
                    }
                })
                .catch(error => {
                    console.error('⚠️ Fout bij ophalen greeting preference:', error);
                });
        }
    }

    setupOptions() {
        this.greetingOptions = [
            { label: `Formeel (Apotheker ${this.lastName})`, value: 'Formeel' },
            { label: `Heer/Mevrouw ${this.lastName}`, value: 'Heer/Mevrouw' },
            { label: `Beste ${this.firstName}`, value: 'Vriendelijk' }
        ];
    }

    handleChange(event) {
        this.selectedValue = event.detail.value;
    }

    handleSave() {
        if (!this.selectedValue) return;

        saveGreetingPreference({
            contactId: this.contactId,
            preference: this.selectedValue
        })
            .then(() => {
                this.showSelector = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Opgeslagen',
                        message: 'Aanspreekvorm werd opgeslagen.',
                        variant: 'success'
                    })
                );
            })
            .catch(error => {
                console.error('❌ Fout bij opslaan voorkeur:', error);
            });
    }
}