public without sharing class ChatterAttachmentLinkerController {

    /**
     * Koppel alle bijlagen van FeedItems van een Case aan de Case zelf.
     * Dit maakt ze zichtbaar voor Experience Site users.
     */
    @AuraEnabled
    public static String linkAttachmentsToCase(Id caseId) {
        System.debug('📎 [AttachmentLinker] Start voor caseId: ' + caseId);

        // Stap 1: verzamel FeedItem Ids van de case
        List<Id> feedItemIds = new List<Id>();
        for (FeedItem fi : [SELECT Id FROM FeedItem WHERE ParentId = :caseId]) {
            feedItemIds.add(fi.Id);
        }

        if (feedItemIds.isEmpty()) {
            return 'Geen FeedItems gevonden voor deze case.';
        }

        // Stap 2: zoek ContentDocumentLinks die aan FeedItems hangen
        Set<Id> documentIds = new Set<Id>();
        for (ContentDocumentLink cdl : [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :feedItemIds
        ]) {
            documentIds.add(cdl.ContentDocumentId);
        }

        if (documentIds.isEmpty()) {
            return 'Geen bijlagen gevonden aan FeedItems.';
        }

        // Stap 3: controleer of ze al aan de case gelinkt zijn
        Set<Id> alreadyLinked = new Set<Id>();
        for (ContentDocumentLink cdl : [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :caseId
              AND ContentDocumentId IN :documentIds
        ]) {
            alreadyLinked.add(cdl.ContentDocumentId);
        }

        // Stap 4: maak nieuwe links aan
        List<ContentDocumentLink> toInsert = new List<ContentDocumentLink>();
        for (Id docId : documentIds) {
            if (!alreadyLinked.contains(docId)) {
                toInsert.add(new ContentDocumentLink(
                    ContentDocumentId = docId,
                    LinkedEntityId = caseId,
                    ShareType = 'V',
                    Visibility = 'AllUsers'
                ));
            }
        }

        if (toInsert.isEmpty()) {
            return 'Alle bijlagen waren al gekoppeld aan de case.';
        }

        insert toInsert;

        return toInsert.size() + ' bijlagen gekoppeld aan de case.';
    }
}