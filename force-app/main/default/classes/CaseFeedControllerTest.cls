@isTest
private class CaseFeedControllerTest {

    @isTest
    static void testGetCaseFeed() {
        // 1. Testdata aanmaken

        // Account (verplicht op Case door validatieregel)
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Contact (voor lookup op Aanmelder__c)
        Contact c = new Contact(LastName = 'Testpersoon');
        insert c;

        // Case aanmaken
        Case testCase = new Case(
            Subject = 'Testincident',
            Status = 'New',
            Origin = 'Web',
            AccountId = acc.Id,
            Aanmelder__c = c.Id
        );
        insert testCase;

        // 2. Gerelateerde communicatie toevoegen

        // FeedItem (Chatter)
        FeedItem post = new FeedItem();
        post.ParentId = testCase.Id;
        post.Body = 'Test Chatter post';
        post.Type = 'TextPost';
        insert post;

        // EmailMessage
        EmailMessage email = new EmailMessage();
        email.ParentId = testCase.Id;
        email.FromName = 'Support Team';
        email.Subject = 'Test email';
        email.TextBody = 'Dit is een testemail.';
        insert email;

        // Task (bijv. telefoon)
        Task taak = new Task(
            WhatId = testCase.Id,
            Subject = 'Test taak',
            Description = 'Beschrijving van testtaak',
            Status = 'Not Started',
            Priority = 'Normal'
        );
        insert taak;

        // 3. Methode testen
        Test.startTest();
        List<CaseFeedController.UnifiedFeedItem> result = CaseFeedController.getCaseFeed(testCase.Id);
        Test.stopTest();

        // 4. Validaties
        System.assertNotEquals(null, result, 'De feed mag niet null zijn');
        System.assertEquals(3, result.size(), 'Er moeten 3 feeditems zijn');

        // Controleren of alle types aanwezig zijn
        Set<String> types = new Set<String>();
        for (CaseFeedController.UnifiedFeedItem item : result) {
            types.add(item.type);
        }

        System.assert(types.contains('Chatter'), 'Chatter post ontbreekt');
        System.assert(types.contains('Email'), 'Email ontbreekt');
        System.assert(types.contains('Taak'), 'Taak ontbreekt');
    }
}