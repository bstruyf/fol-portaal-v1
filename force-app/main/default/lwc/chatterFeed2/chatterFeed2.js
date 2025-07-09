import { LightningElement } from 'lwc';
import getFeedItems from '@salesforce/apex/ChatterFeedController2.getChatterFeed';

export default class ChatterFeed2 extends LightningElement {
    feedItems;
    error;
    recordId;

    connectedCallback() {
        const path = window.location.pathname;
        const match = path.match(/\/case\/([a-zA-Z0-9]{15,18})/);
        if (match) {
            this.recordId = match[1];
            console.log('📘 [ChatterFeed2] ✅ Correcte recordId uit URL gehaald:', this.recordId);
            this.loadFeed();
        } else {
            console.warn('📘 [ChatterFeed2] ⚠️ Geen geldig recordId gevonden in pad:', path);
        }
    }

    loadFeed() {
        if (!this.recordId) {
            console.warn('📘 [ChatterFeed2] ⛔️ recordId is undefined bij loadFeed');
            return;
        }

        console.log('📘 [ChatterFeed2] 🚀 Ophalen feeditems voor recordId:', this.recordId);

        getFeedItems({ caseId: this.recordId })
            .then(data => {
                console.log('📘 [ChatterFeed2] ✅ Feed ontvangen met', data.length, 'items');
                this.feedItems = data;

                setTimeout(() => {
                    data.forEach(item => {
                        console.log('📘 [ChatterFeed2] 🧾 HTML voor item', item.id, item.content);
                        const container = this.template.querySelector(`[data-id="${item.id}"]`);
                        if (container && item.content) {
                            container.innerHTML = item.content;
                        }
                    });
                }, 0);
            })
            .catch(error => {
                console.error('📘 [ChatterFeed2] ❌ Fout bij ophalen feed:', error);
                this.error = error.body?.message || 'Onbekende fout';
            });
    }
}