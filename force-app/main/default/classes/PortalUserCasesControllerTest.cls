@isTest
private class PortalUserCasesControllerTest {
    @testSetup
    static void setupData() {
        // Maak een test Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Maak een test Contact
        Contact testContact = new Contact(FirstName = 'Test', LastName = 'User', AccountId = testAccount.Id);
        insert testContact;

        // Maak een test User met het testContact
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Farmad Portal User' LIMIT 1];
        User testUser = new User(
            Username = 'testuser@test.com',
            Email = 'testuser@test.com',
            LastName = 'User',
            Alias = 'tuser',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ContactId = testContact.Id
        );
        insert testUser;

        // Maak een test Case met de PortalUserID van de testgebruiker
        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'New',
            PortalUserID__c = testUser.Id,  // Dit is belangrijk voor de test
            AccountId = testAccount.Id
        );
        insert testCase;
    }

    @isTest
static void testGetPortalUserCases() {
    // Simuleer de ingelogde gebruiker
    User testUser = [SELECT Id FROM User WHERE Username = 'testuser@test.com' LIMIT 1];

    System.runAs(testUser) {
        Test.startTest();
        List<Case> result = PortalUserCasesController.getPortalUserCases();
        Test.stopTest();

        // DEBUG: Controleer of er cases zijn opgehaald
        System.debug('Aantal cases opgehaald: ' + result.size());

        // Controleer of de case correct is opgehaald
        System.assertNotEquals(0, result.size(), 'Er moeten cases worden opgehaald.');

        // ✅ Hier expliciet het veld `PortalUserID__c` controleren
        Case testCase = [SELECT Id, Subject, PortalUserID__c FROM Case WHERE Id = :result[0].Id];

        System.assertEquals('Test Case', testCase.Subject, 'De case-onderwerp moet correct zijn.');
        System.assertEquals(testUser.Id, testCase.PortalUserID__c, 'De PortalUserID moet overeenkomen.');
    }
}
}