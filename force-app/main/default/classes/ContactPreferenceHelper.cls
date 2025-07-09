// US-2025-07-06-001 - Opslaan en ophalen van aanspreekvoorkeur

public with sharing class ContactPreferenceHelper {

    @AuraEnabled(cacheable=true)
    public static String getGreetingPreference(Id contactId) {
        if (contactId == null) return null;

        Contact c = [SELECT Preferred_Greeting__c FROM Contact WHERE Id = :contactId LIMIT 1];
        return c.Preferred_Greeting__c;
    }

    @AuraEnabled
    public static void saveGreetingPreference(Id contactId, String preference) {
        if (String.isBlank(preference)) {
            throw new AuraHandledException('Geen voorkeur opgegeven');
        }

        Contact c = new Contact(Id = contactId);
        c.Preferred_Greeting__c = preference;
        update c;
    }
@AuraEnabled(cacheable=true)
public static String getContactFullName(Id contactId) {
    Contact c = [SELECT FirstName, LastName FROM Contact WHERE Id = :contactId LIMIT 1];
    return c.FirstName + '|' + c.LastName;
}
}