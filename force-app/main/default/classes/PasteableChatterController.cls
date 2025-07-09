public with sharing class PasteableChatterController {
    /**
     * 1) Upload een Base64-afbeelding als ContentVersion en return de ContentDocumentId (069…)
     */
    @AuraEnabled
    public static Id uploadImage(String base64Data, String fileName) {
        System.debug(LoggingLevel.DEBUG, '▶ uploadImage START – fileName=' + fileName
            + ', base64Data length=' + (base64Data != null ? base64Data.length() : 0));
        try {
            ContentVersion cv = new ContentVersion(
                Title        = fileName,
                PathOnClient = fileName,
                VersionData  = EncodingUtil.base64Decode(base64Data)
            );
            insert cv;
            System.debug(LoggingLevel.DEBUG, '   ✅ ContentVersion inserted, VersionId=' + cv.Id);

            cv = [SELECT Id, ContentDocumentId
                  FROM ContentVersion
                  WHERE Id = :cv.Id
                  LIMIT 1];
            System.debug(LoggingLevel.DEBUG, '   → Queried ContentVersion: VersionId=' 
                + cv.Id + ', DocumentId=' + cv.ContentDocumentId);
            return cv.ContentDocumentId;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, '❌ uploadImage failed: ' + e);
            throw e;
        } finally {
            System.debug(LoggingLevel.DEBUG, '◀ uploadImage END');
        }
    }

    /**
     * 2) Ontvangt de volledig genormaliseerde HTML-body met alleen {img:069…:alt}-placeholders
     *    en post die vervolgens via ConnectApiHelper.
     *    Debug-log toont welke document-IDs er meegaan.
     */
    @AuraEnabled
    public static void postRichText(Id recordId, String htmlBody) {
        System.debug(LoggingLevel.DEBUG, '▶ postRichText START – recordId=' 
            + recordId + ', raw htmlBody=' + htmlBody);

        // Zorg dat we nooit null doorgeven
        String body = (htmlBody == null) ? '' : htmlBody;
        System.debug(LoggingLevel.DEBUG, '   Normalized htmlBody:\n' + body);

        // Zoek en log alle 069… document IDs in de placeholders
        Pattern docPattern = Pattern.compile('\\{img:(069[0-9A-Za-z]{12,15}):');
        Matcher docMatcher = docPattern.matcher(body);
        List<String> docIds = new List<String>();
        while (docMatcher.find()) {
            docIds.add(docMatcher.group(1));
        }
        System.debug(LoggingLevel.DEBUG, '   Detected document-IDs in placeholders: ' + docIds);

        // Post via ConnectApiHelper
        ConnectApiHelper.postFeedItemWithRichText(
            null,        // communityId = null voor interne org
            recordId,    // subjectId (bv. de Case)
            body         // je genormaliseerde HTML incl. {img:069…:alt}
        );

        System.debug(LoggingLevel.DEBUG, '◀ postRichText END');
    }
}