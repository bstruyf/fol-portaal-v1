public without sharing class CaseFileUploaderController {
    @AuraEnabled
    public static String uploadFileToCaseAndReturnDistributionId(Id caseId, String base64Content, String fileName) {
        System.debug('Begin uploadFileToCase');
        if (caseId == null || base64Content == null || fileName == null) {
            System.debug('Invalide input: ' + caseId + ', ' + base64Content + ', ' + fileName);
            throw new AuraHandledException('Argument cannot be null. Ensure caseId, base64Content, and fileName are provided.');
        }

        try {
            // Decode base64 naar blob
            System.debug('Decoding base64 content...');
            Blob fileBody = EncodingUtil.base64Decode(base64Content);
            System.debug('Decoded Blob: ' + fileBody);

            // Maak ContentVersion
            ContentVersion cv = new ContentVersion();
            cv.Title = fileName;
            cv.PathOnClient = fileName;
            cv.VersionData = fileBody;
            insert cv;
            System.debug('Inserted ContentVersion: ' + cv.Id);

            // Haal ContentDocumentId op
            Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1].ContentDocumentId;
            System.debug('Retrieved ContentDocumentId: ' + contentDocumentId);

            Id latestVersionId = [SELECT LatestPublishedVersionId FROM ContentDocument WHERE Id = :contentDocumentId LIMIT 1].LatestPublishedVersionId;
            System.debug('Retrieved LatestPublishedVersionId: ' + latestVersionId);

            // Koppel aan Case
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = contentDocumentId;
            cdl.LinkedEntityId = caseId;
            cdl.ShareType = 'V';
            insert cdl;
            System.debug('Inserted ContentDocumentLink: ' + cdl.Id);

            // Maak publieke link
            ContentDistribution dist = new ContentDistribution();
            dist.Name = fileName;
            dist.ContentVersionId = latestVersionId;
            dist.PreferencesAllowViewInBrowser = true;
            dist.PreferencesAllowOriginalDownload = true;
                insert dist;
    System.debug('DistributionPublicUrl: ' + dist.DistributionPublicUrl);
    System.debug('ContentDistributionId: ' + dist.Id);
    return dist.Id; // <<< dit is wat je wil

        } catch (Exception e) {
            System.debug('Fout tijdens upload: ' + e.getMessage());
            throw new AuraHandledException('Error uploading file: ' + e.getMessage());
        }
    }
@AuraEnabled
public static String getDistributionUrl(Id distributionId) {
    ContentDistribution dist = [SELECT DistributionPublicUrl FROM ContentDistribution WHERE Id = :distributionId];
    return dist.DistributionPublicUrl;
}
}