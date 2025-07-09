public with sharing class ChatterPost2Controller {
    
    @AuraEnabled
    public static void postRichText(Id recordId, String htmlBody) {
        System.debug(LoggingLevel.DEBUG, '▶ postRichText START');
        System.debug(LoggingLevel.DEBUG, 'recordId=' + recordId);
        System.debug(LoggingLevel.DEBUG, 'htmlBody=' + htmlBody);

        if (String.isBlank(recordId) || String.isBlank(htmlBody)) {
            throw new AuraHandledException('recordId en htmlBody zijn verplicht.');
        }

        try {
            // Gebruik je eigen helper en rich text met {img:069...}
            ConnectApiHelper.postFeedItemWithRichText(null, recordId, htmlBody);
            System.debug(LoggingLevel.DEBUG, '✅ postFeedItemWithRichText uitgevoerd');
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, '❌ Fout bij posten: ' + e.getMessage());
            throw new AuraHandledException('Fout bij posten: ' + e.getMessage());
        }

        System.debug(LoggingLevel.DEBUG, '◀ postRichText END');
    }
@AuraEnabled
    public static Id ensureDocumentIdForVersion(Id versionId) {
        System.debug('📥 Start ensureDocumentIdForVersion voor: ' + versionId);

        ContentVersion cv = [
            SELECT Id, Title, VersionData, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :versionId
            LIMIT 1
        ];

        if (cv.ContentDocumentId != null) {
            System.debug('✅ Reeds gekoppeld aan ContentDocument: ' + cv.ContentDocumentId);
            return cv.ContentDocumentId;
        }

        System.debug('ℹ️ Geen ContentDocumentId gevonden. Heruploaden...');

        ContentVersion newCv = new ContentVersion(
            Title        = cv.Title,
            PathOnClient = cv.Title,
            VersionData  = cv.VersionData
        );
        insert newCv;

        ContentVersion inserted = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :newCv.Id
            LIMIT 1
        ];

        System.debug('✅ Nieuw ContentDocumentId: ' + inserted.ContentDocumentId);
        return inserted.ContentDocumentId;
    }
}