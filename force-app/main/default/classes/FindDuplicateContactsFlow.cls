public with sharing class FindDuplicateContactsFlow {

    public class ContactWrapper {
        @InvocableVariable(label='Contact Id')
        public Id contactId;

        @InvocableVariable(label='Reden duplicatie')
        public String reason;
    }

    @InvocableMethod(label='Zoek dubbele Contacten')
    public static List<ContactWrapper> findDuplicates() {
        List<ContactWrapper> output = new List<ContactWrapper>();

        // 1. Dubbele contacten op e-mailadres
        Map<String, List<Contact>> emailMap = new Map<String, List<Contact>>();
        for (Contact c : [SELECT Id, FirstName, LastName, Email FROM Contact WHERE Email != null]) {
            if (!emailMap.containsKey(c.Email)) {
                emailMap.put(c.Email, new List<Contact>());
            }
            emailMap.get(c.Email).add(c);
        }
        for (String email : emailMap.keySet()) {
            List<Contact> dupes = emailMap.get(email);
            if (dupes.size() > 1) {
                for (Contact c : dupes) {
                    ContactWrapper cw = new ContactWrapper();
                    cw.contactId = c.Id;
                    cw.reason = 'Dubbel e-mailadres: ' + email;
                    output.add(cw);
                }
            }
        }

        // 2. Contacten met en zonder e-mail maar zelfde naam
        Map<String, List<Contact>> nameMap = new Map<String, List<Contact>>();
        for (Contact c : [SELECT Id, FirstName, LastName, Email FROM Contact]) {
            String nameKey = (c.FirstName + ':' + c.LastName).toLowerCase();
            if (!nameMap.containsKey(nameKey)) {
                nameMap.put(nameKey, new List<Contact>());
            }
            nameMap.get(nameKey).add(c);
        }
        for (String name : nameMap.keySet()) {
            List<Contact> sameName = nameMap.get(name);
            Boolean hasWithEmail = false;
            Boolean hasWithoutEmail = false;
            for (Contact c : sameName) {
                if (String.isNotBlank(c.Email)) {
                    hasWithEmail = true;
                } else {
                    hasWithoutEmail = true;
                }
            }
            if (hasWithEmail && hasWithoutEmail) {
                for (Contact c : sameName) {
                    ContactWrapper cw = new ContactWrapper();
                    cw.contactId = c.Id;
                    cw.reason = 'Naamduplicatie met en zonder e-mail: ' + name;
                    output.add(cw);
                }
            }
        }

        // 3. Algemene e-mailadressen (maar geen 'Apotheekteam')
        List<Contact> generalEmails = [
            SELECT Id, FirstName, LastName, Email FROM Contact 
            WHERE 
                (Email LIKE 'info@%' OR Email LIKE 'contact@%' OR Email LIKE 'team@%') 
                AND LastName != 'Apotheekteam'
        ];
        for (Contact c : generalEmails) {
            ContactWrapper cw = new ContactWrapper();
            cw.contactId = c.Id;
            cw.reason = 'Algemeen e-mailadres zonder Apotheekteam';
            output.add(cw);
        }

        return output;
    }
}