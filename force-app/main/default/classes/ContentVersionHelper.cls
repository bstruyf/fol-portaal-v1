public with sharing class ContentVersionHelper {

    /**
     * Zorgt ervoor dat een gegeven ContentVersion een geldig ContentDocumentId krijgt.
     * Indien reeds aanwezig, retourneert het bestaande documentId.
     * Indien niet, dupliceert hij de versie en retourneert het nieuwe documentId.
     *
     * @param versionId De Id van de originele ContentVersion (bijv. 0EM...).
     * @return De gekoppelde ContentDocumentId (069...)
     */
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