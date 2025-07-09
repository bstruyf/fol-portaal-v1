public with sharing class ChatterPostController {

    @AuraEnabled
    public static Map<String, Id> uploadImage(String base64Data, String fileName) {
        System.debug(LoggingLevel.DEBUG, '▶ uploadImage START');
        System.debug(LoggingLevel.DEBUG, '   Received fileName     = ' + fileName);
        Integer len = (base64Data == null ? 0 : base64Data.length());
        System.debug(LoggingLevel.DEBUG, '   Received base64Data length = ' + len);
        if (base64Data != null && base64Data.length() > 50) {
            System.debug(LoggingLevel.DEBUG, '   Received base64Data (first 50 chars) = ' 
                + base64Data.substring(0, 50) + '…');
        }

        Map<String, Id> result = new Map<String, Id>();
        try {
            Blob decoded = EncodingUtil.base64Decode(base64Data);
            System.debug(LoggingLevel.DEBUG, '   Decoded Blob size = ' + decoded.size());

            ContentVersion cv = new ContentVersion(
                Title        = fileName,
                PathOnClient = fileName,
                VersionData  = decoded
            );
            insert cv;
            System.debug(LoggingLevel.DEBUG, '   ✅ ContentVersion inserted, VersionId = ' + cv.Id);

            cv = [SELECT Id, ContentDocumentId
                  FROM ContentVersion
                  WHERE Id = :cv.Id
                  LIMIT 1];
            System.debug(LoggingLevel.DEBUG, '   → Queried ContentDocumentId = ' + cv.ContentDocumentId);

            result.put('versionId',  cv.Id);
            result.put('documentId', cv.ContentDocumentId);
            System.debug(LoggingLevel.DEBUG, '◀ uploadImage END – returning ' + result);
            return result;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, '❌ uploadImage failed: ' + e.getMessage());
            throw new AuraHandledException('Upload image mislukt: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String fetchExistingVersionBase64(Id versionId) {
        ContentVersion cv = [
            SELECT VersionData
            FROM ContentVersion
            WHERE Id = :versionId
            LIMIT 1
        ];
        return EncodingUtil.base64Encode(cv.VersionData);
    }

    @AuraEnabled
    public static void postRichText(Id recordId, String htmlBody) {
        System.debug(LoggingLevel.DEBUG, '▶ postRichText START – recordId = ' + recordId 
            + ', raw htmlBody = ' + htmlBody);

        String body = (htmlBody == null) ? '' : htmlBody;
        System.debug(LoggingLevel.DEBUG, '🔍 Raw input body:\n' + htmlBody);

        body = body
            .replaceAll('(?i)<strong>', '<b>')
            .replaceAll('(?i)</strong>', '</b>')
            .replaceAll('(?i)<em>',    '<i>')
            .replaceAll('(?i)</em>',   '</i>')
            .replaceAll('(?i)<u>',     '<u>')
            .replaceAll('(?i)</u>',    '</u>')
            .replaceAll('(?i)<del>',   '<s>')
            .replaceAll('(?i)</del>',  '</s>')
            .replaceAll('(?i)<strike>','<s>')
            .replaceAll('(?i)</strike>','</s>')
            .replaceAll('(?i)<p><br></p>','<p>&nbsp;</p>');

        System.debug(LoggingLevel.DEBUG, '🔁 After tag normalization:\n' + body);

        body = convertToParagraphs(body);
        System.debug(LoggingLevel.DEBUG, '✅ After convertToParagraphs:\n' + body);

        body = body
            .replaceAll(
              '(?i)<img\\s+[^>]*src="[^"]*?/servlet/rtaImage\\?refid=([0-9A-Za-z]{15,18})"[^>]*alt="([^"]*)"[^>]*>',
              '{img:$1:$2}'
            )
            .replaceAll(
              '(?i)<img\\s+[^>]*src="[^"]*?/servlet/rtaImage\\?refid=([0-9A-Za-z]{15,18})"[^>]*>',
              '{img:$1:}'
            );
        System.debug(LoggingLevel.DEBUG, '   After placeholder replace:\n' + body);

        Pattern ph = Pattern.compile('\\{img:([0-9A-Za-z]{15,18}):([^}]*)\\}');
        Matcher mh = ph.matcher(body);
        Set<Id> versionIds = new Set<Id>();
        Map<Id, String> altMap = new Map<Id, String>();
        while (mh.find()) {
            Id verId = (Id) mh.group(1);
            String alt = mh.group(2);
            versionIds.add(verId);
            altMap.put(verId, alt);
        }
        System.debug(LoggingLevel.DEBUG, '   Found versionIds: ' + versionIds);

        if (!versionIds.isEmpty()) {
            Map<Id, Id> verToDoc = new Map<Id, Id>();
            for (ContentVersion cv : [
                SELECT Id, ContentDocumentId
                FROM ContentVersion
                WHERE Id IN :versionIds
            ]) {
                verToDoc.put(cv.Id, cv.ContentDocumentId);
                System.debug(LoggingLevel.DEBUG, '     Mapping version ' 
                    + cv.Id + ' → document ' + cv.ContentDocumentId);
            }

            String newBody = '';
            Integer lastPos = 0;
            mh.reset();
            while (mh.find()) {
                newBody += body.substring(lastPos, mh.start());
                Id verId = (Id) mh.group(1);
                String alt = mh.group(2);

                if (!verToDoc.containsKey(verId)) {
                    System.debug(LoggingLevel.WARN, '⚠️ Geen ContentDocumentId gevonden voor versieId: ' + verId);
                    continue;
                }

                Id docId = verToDoc.get(verId);
                newBody += '{img:' + docId + ':' + alt + '}';
                lastPos = mh.end();
            }
            newBody += body.substring(lastPos);
            body = convertToParagraphs(newBody);
            System.debug(LoggingLevel.DEBUG, '   After version→document translation:\n' + body);
        }

        System.debug(LoggingLevel.DEBUG, '   Posting via ConnectApiHelper, final body:\n' + body);
        ConnectApiHelper.postFeedItemWithRichText(
            null,
            recordId,
            body
        );
        System.debug(LoggingLevel.DEBUG, '◀ postRichText END');
    }

    private static String convertToParagraphs(String body) {
        List<String> parts = body.split('(?i)<br\\s*/?>');
        List<String> paragraphs = new List<String>();

        for (String part : parts) {
            String trimmed = String.isBlank(part) ? '&nbsp;' : part.trim();
            String para = '<p>' + trimmed + '</p>';
            System.debug(LoggingLevel.DEBUG, '➕ paragraph added: ' + para);
            paragraphs.add(para);
        }

        String result = String.join(paragraphs, '');
        System.debug(LoggingLevel.DEBUG, '📦 Final paragraph body:\n' + result);
        return result;
    }
@AuraEnabled
public static Id resolveAndReuploadVersion(Id versionId) {
    System.debug(LoggingLevel.DEBUG, '▶ resolveAndReuploadVersion START for ' + versionId);
    
    try {
        ContentVersion existing = [
            SELECT Id, Title, VersionData
            FROM ContentVersion
            WHERE Id = :versionId
            LIMIT 1
        ];
        
        ContentVersion newCv = new ContentVersion(
            Title = 'resolved-' + existing.Title,
            PathOnClient = existing.Title,
            VersionData = existing.VersionData
        );
        insert newCv;
        System.debug(LoggingLevel.DEBUG, '✅ Re-uploaded version as: ' + newCv.Id);
        
        ContentVersion inserted = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :newCv.Id
            LIMIT 1
        ];
        
        System.debug(LoggingLevel.DEBUG, '▶ resolveAndReuploadVersion END → ' + inserted.ContentDocumentId);
        return inserted.ContentDocumentId;
        
    } catch (Exception e) {
        System.debug(LoggingLevel.ERROR, '❌ Error resolving versionId ' + versionId + ': ' + e.getMessage());
        throw new AuraHandledException('Kon afbeelding niet verwerken: ' + e.getMessage());
    }
}
@AuraEnabled
public static Id ensureDocumentIdForVersion(Id versionId) {
    ContentVersion cv = [SELECT Id, ContentDocumentId, VersionData, Title FROM ContentVersion WHERE Id = :versionId LIMIT 1];
    if (cv.ContentDocumentId != null) {
        return cv.ContentDocumentId;
    }

    // Re-upload exact dezelfde afbeelding
    ContentVersion newCv = new ContentVersion(
        Title        = cv.Title,
        PathOnClient = cv.Title,
        VersionData  = cv.VersionData
    );
    insert newCv;

    newCv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :newCv.Id];
    return newCv.ContentDocumentId;
}
}