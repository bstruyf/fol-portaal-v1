import { LightningElement, track, wire } from 'lwc';
import getUserCases from '@salesforce/apex/PortalUserCasesController.getPortalUserCases';

export default class PortalUserCasesV2 extends LightningElement {
    @track cases = [];
    @track filteredCases = [];
    @track searchKey = '';
    @track sortedBy;
    @track sortedDirection;

    @track columns = [
        {
            label: 'Meldingnummer',
            fieldName: 'caseUrl',
            type: 'url',
            typeAttributes: { label: { fieldName: 'CaseNumber' }, target: '_self' },
            sortable: true,
            initialWidth: 130
        },
        {
            label: 'Aanmelddatum',
            fieldName: 'CreatedDateFormatted',
            type: 'text',
            sortable: true,
            initialWidth: 140
        },
        {
            label: 'Streefdatum',
            fieldName: 'StreefdatumFormatted',
            type: 'text',
            sortable: true,
            initialWidth: 140
        },
        {
            label: 'Aanmelder',
            fieldName: 'AanmelderNaam',
            type: 'text',
            sortable: true,
            initialWidth: 160
        },
        {
            label: 'Status',
            fieldName: 'Status',
            type: 'text',
            sortable: true,
            initialWidth: 100
        },
        {
            label: 'Owner',
            fieldName: 'OwnerNaam',
            type: 'text',
            sortable: true,
            initialWidth: 160
        },
        {
            label: 'Korte Omschrijving',
            fieldName: 'KorteOmschrijving',
            type: 'text',
            sortable: true,
            cellAttributes: {
                tooltip: { fieldName: 'LangeOmschrijving' }
            }
        }
    ];

    @wire(getUserCases)
    wiredCases({ data, error }) {
        if (data) {
            this.cases = data.map(c => {
                let ownerNaam = '';
                if (c.Owner) {
                    if (c.Owner.FirstName && c.Owner.LastName) {
                        ownerNaam = `${c.Owner.FirstName} ${c.Owner.LastName}`;
                    } else if (c.Owner.Name) {
                        ownerNaam = c.Owner.Name;
                    }
                }

                const created = new Date(c.CreatedDate);
                const streef = c.Date_Time_target__c ? new Date(c.Date_Time_target__c) : null;

                return {
                    ...c,
                    caseUrl: window.location.origin + '/FOLPortaal/case/' + c.Id,
                    CaseNumber: c.CaseNumber,
                    CreatedDateRaw: created,
                    CreatedDateFormatted: created.toLocaleDateString(),
                    StreefdatumRaw: streef,
                    StreefdatumFormatted: streef ? streef.toLocaleDateString() : '',
                    AanmelderNaam: c.Aanmelder__r ? c.Aanmelder__r.Name : '',
                    OwnerNaam: ownerNaam,
                    KorteOmschrijving: c.Subject,
                    LangeOmschrijving: c.Description || ''
                };
            });
            this.filteredCases = [...this.cases];
        } else if (error) {
            console.error('Fout bij het ophalen van cases', error);
        }
    }

    handleSort(event) {
        const { fieldName, sortDirection } = event.detail;

        const sortField = fieldName === 'CreatedDateFormatted' ? 'CreatedDateRaw' :
                          fieldName === 'StreefdatumFormatted' ? 'StreefdatumRaw' :
                          fieldName;

        const sortedData = [...this.filteredCases];
        sortedData.sort((a, b) => {
            const valA = a[sortField];
            const valB = b[sortField];

            if (valA instanceof Date && valB instanceof Date) {
                return valA - valB;
            }
            return (valA || '').toString().localeCompare((valB || '').toString(), undefined, { numeric: true });
        });

        this.filteredCases = sortDirection === 'asc' ? sortedData : sortedData.reverse();
        this.sortedBy = fieldName;
        this.sortedDirection = sortDirection;
    }

    handleSearch(event) {
        this.searchKey = event.target.value.toLowerCase();
        if (!this.searchKey) {
            this.filteredCases = [...this.cases];
            return;
        }

        this.filteredCases = this.cases.filter(c =>
            (c.CaseNumber || '').toLowerCase().includes(this.searchKey) ||
            (c.CreatedDateFormatted || '').toLowerCase().includes(this.searchKey) ||
            (c.StreefdatumFormatted || '').toLowerCase().includes(this.searchKey) ||
            (c.AanmelderNaam || '').toLowerCase().includes(this.searchKey) ||
            (c.Status || '').toLowerCase().includes(this.searchKey) ||
            (c.OwnerNaam || '').toLowerCase().includes(this.searchKey) ||
            (c.KorteOmschrijving || '').toLowerCase().includes(this.searchKey) ||
            (c.LangeOmschrijving || '').toLowerCase().includes(this.searchKey)
        );
    }
}