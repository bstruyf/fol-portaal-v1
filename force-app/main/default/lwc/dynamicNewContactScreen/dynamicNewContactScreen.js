import { LightningElement, api, track } from 'lwc';

export default class NewContactPopup extends LightningElement {
    @api selectedValue; // Krijgt de waarde van het bestaande "Aanmelder" veld uit de Flow
    @track showPopup = false;

    @track firstName = '';
    @track lastName = '';
    @track email = '';
    @track phone = '';

    // Detecteer wijziging in het "Aanmelder" veld
    @api
    set anmelder(value) {
        this.selectedValue = value;
        if (value === 'Nieuwe Contactpersoon Toevoegen') {
            this.showPopup = true;
        } else {
            this.showPopup = false;
        }
    }
    
    get anmelder() {
        return this.selectedValue;
    }

    // Verwerk inputvelden
    handleInputChange(event) {
        const field = event.target.name;
        this[field] = event.target.value;
    }

    // Sluit de pop-up zonder opslaan
    closePopup() {
        this.showPopup = false;
    }

    // Bevestig en stuur gegevens terug naar de Flow
    saveContact() {
        const contactData = {
            firstName: this.firstName,
            lastName: this.lastName,
            email: this.email,
            phone: this.phone
        };

        // Stuur de nieuwe contactgegevens terug naar de Flow
        this.dispatchEvent(new CustomEvent('contactsave', { detail: contactData }));

        // Sluit de pop-up na het opslaan
        this.showPopup = false;
    }
}