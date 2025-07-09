import { LightningElement, track } from 'lwc';
import suggestKnowledgeArticles from '@salesforce/apex/CaseLauncherController.suggestKnowledgeArticles';

export default class PortalKbSuggest extends LightningElement {
    @track aantekeningen = '';
    @track suggestedArticles = [];
    @track debugText = ''; // 🔍 zichtbaar in de HTML

    handleAantekeningChange(event) {
        console.log("🔔 handleAantekeningChange getriggerd"); // ✅ DEBUG
        this.aantekeningen = event.target.value;
        const plainText = (this.aantekeningen || '').replace(/<[^>]+>/g, '').trim();

        this.debugText = `✍️ plainText = "${plainText}" (${plainText.length} tekens)`;

        if (plainText.length >= 3) {
            this.debugText += `\n🔍 suggestKnowledgeArticles wordt aangeroepen...`;
            console.log("🔍 suggestKnowledgeArticles wordt aangeroepen met query:", plainText);

            suggestKnowledgeArticles({ query: plainText })
                .then(result => {
                    this.suggestedArticles = result.map(a => ({
                        Id: a.Id,
                        Title: a.Title,
                        Environment: a.Environment__c,
                        Cause: a.Cause__c,
                        Problem: a.Problem__c,
                        Answer: a.Answer__c,
                        url: `/lightning/r/Knowledge__kav/${a.Id}/view`,
                        showPopover: false
                    }));

                    this.debugText += `\n✅ ${this.suggestedArticles.length} artikelen ontvangen.`;
                })
                .catch(error => {
                    console.error('❌ Fout bij ophalen suggesties:', error);
                    this.suggestedArticles = [];
                    this.debugText += `\n❌ Fout: ${JSON.stringify(error)}`;
                });
        } else {
            this.suggestedArticles = [];
            this.debugText += `\nℹ️ Geen zoekopdracht uitgevoerd (te kort).`;
        }
    }

 handleTitleClick(event) {
    console.log('🔔 handleTitleClick getriggerd');
    const id = event.target.dataset.id;

    this.suggestedArticles = this.suggestedArticles.map(article => ({
        ...article,
        showPopover: article.Id === id ? !article.showPopover : false
    }));
}

connectedCallback() {
    // Sluit popovers bij klikken buiten de component
    document.addEventListener('click', this.handleDocumentClick);
}

disconnectedCallback() {
    document.removeEventListener('click', this.handleDocumentClick);
}


    handleInsertAnswer(event) {
        const antwoord = event.target.dataset.answer;
        this.debugText += `\n➕ Antwoord gekozen:\n${antwoord}`;
        // ... hier kan later logica worden toegevoegd
    }
}