@IsTest
private class CaseOwnerHandlerTest {
    @TestSetup
    static void setupData() {
        // 1) Maak een Queue “TestQueue” aan
        Group q = new Group(
            Type = 'Queue',
            Name = 'TestQueue'
        );
        insert q;
        // 2) Koppel deze Queue aan het Case-object
        QueueSobject qs = new QueueSobject(
            QueueId     = q.Id,
            SobjectType = 'Case'
        );
        insert qs;
    }

    @IsTest
    static void testOwnerChangesWhenBehandelaarsGroepUpdates() {
        // Haal de TestQueue op
        Group queueRec = [SELECT Id, Name FROM Group WHERE Name = 'TestQueue' LIMIT 1];

        // 3) Maak een Case zonder BehandelaarsGroep__c
        Case c = new Case(
            Subject = 'Unit test case',
            Status  = 'New'
        );
        insert c;

        // Preconditie: de queue is nog niet de owner
        System.assertNotEquals(queueRec.Id, c.OwnerId,
            'Preconditie: de queue mag nog niet eigenaar zijn');

        // 4) Update de BehandelaarsGroep__c naar onze TestQueue
        c.BehandelaarsGroep__c = 'TestQueue';
        update c;

        // 5) Herlaad en controleer dat OwnerId is aangepast
        Case c2 = [SELECT OwnerId, BehandelaarsGroep__c 
                     FROM Case 
                    WHERE Id = :c.Id];
        System.assertEquals('TestQueue', c2.BehandelaarsGroep__c,
            'BehandelaarsGroep__c moet TestQueue zijn');
        System.assertEquals(queueRec.Id, c2.OwnerId,
            'Na update van BehandelaarsGroep__c moet OwnerId gelijk zijn aan de queue');
    }

    @IsTest
    static void testOwnerUnchangedWhenNoGroepChange() {
        // Haal de TestQueue op
        Group queueRec = [SELECT Id FROM Group WHERE Name = 'TestQueue' LIMIT 1];

        // 6) Maak een Case met lege BehandelaarsGroep__c
        Case c = new Case(
            Subject              = 'Andere case',
            Status               = 'New',
            BehandelaarsGroep__c = null
        );
        insert c;

        // 7) Update een ander veld, niet BehandelaarsGroep__c
        c.Status = 'Working';
        update c;

        // 8) Controleer dat OwnerId NIET naar de queue is gegaan
        Case c2 = [SELECT OwnerId FROM Case WHERE Id = :c.Id];
        System.assertNotEquals(queueRec.Id, c2.OwnerId,
            'Als BehandelaarsGroep__c niet verandert, mag OwnerId niet aangepast worden');
    }
}