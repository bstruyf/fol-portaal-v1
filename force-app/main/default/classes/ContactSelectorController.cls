public with sharing class ContactSelectorController {

    @AuraEnabled(cacheable=true)
    public static List<ContactWrapper> getContactRelations(Id accountId) {
        if (String.isBlank(accountId)) return new List<ContactWrapper>();

        List<ContactWrapper> results = new List<ContactWrapper>();

        // Probeer via AccountContactRelation
        List<AccountContactRelation> acrList = [
            SELECT ContactId, Contact.FirstName, Contact.LastName, Contact.Email, Roles
            FROM AccountContactRelation
            WHERE AccountId = :accountId
              AND ContactId != null
              AND IsDeleted = FALSE
              AND Contact.IsDeleted = FALSE
        ];

        if (!acrList.isEmpty()) {
            for (AccountContactRelation acr : acrList) {
                if (acr.Contact != null) {
                    results.add(new ContactWrapper(
                        acr.ContactId,
                        acr.Contact.FirstName,
                        acr.Contact.LastName,
                        acr.Contact.Email,
                        acr.Roles
                    ));
                }
            }
            return results;
        }

        // Fallback: via standaard AccountId-relatie
        for (Contact c : [
            SELECT Id, FirstName, LastName, Email
            FROM Contact
            WHERE AccountId = :accountId
              AND IsDeleted = FALSE
        ]) {
            results.add(new ContactWrapper(
                c.Id,
                c.FirstName,
                c.LastName,
                c.Email,
                null // geen rol beschikbaar via standaard relatie
            ));
        }

        return results;
    }

    public class ContactWrapper {
        @AuraEnabled public String contactId;
        @AuraEnabled public String firstName;
        @AuraEnabled public String lastName;
        @AuraEnabled public String email;
        @AuraEnabled public String role;

        public ContactWrapper(String contactId, String firstName, String lastName, String email, String role) {
            this.contactId = contactId;
            this.firstName = firstName;
            this.lastName = lastName;
            this.email = email;
            this.role = role;
        }
    }
}