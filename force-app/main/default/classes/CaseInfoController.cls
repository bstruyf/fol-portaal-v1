public without sharing class CaseInfoController {
    @AuraEnabled(cacheable=true)
    public static Case getCaseInfo(Id caseId) {
        if (caseId == null) {
            return null;
        }
        List<Case> records = [
            SELECT Id, CaseNumber, Subject, Status, CreatedDate, Date_Time_target__c,
       Description2__c, OwnerId, Owner.Type, Aanmelder__r.Name,
       Owner.FirstName, Owner.LastName
FROM Case
WHERE Id = :caseId
        ];
        if (records.isEmpty()) {
            return null;
        }
        return records[0];
    }

    // Wrapper-klasse voor een “File” (Lightning File) die we in LWC kunnen gebruiken
    public class FileWrapper {
        @AuraEnabled public String title;
        @AuraEnabled public String downloadUrl;

        public FileWrapper(String title, String publicUrl) {
    this.title = title;
    this.downloadUrl = publicUrl;
}
    }

    @AuraEnabled(cacheable=true)
public static List<FileWrapper> getCaseFiles(Id caseId) {
    if (caseId == null) {
        return new List<FileWrapper>();
    }

    // Stap 1: Haal alle ContentDocumentLinks op
    List<ContentDocumentLink> links = [
        SELECT ContentDocumentId,
               ContentDocument.Title,
               ContentDocument.LatestPublishedVersionId
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :caseId
    ];

    Map<Id, String> versionIdToTitle = new Map<Id, String>();
    Set<Id> versionIds = new Set<Id>();

    for (ContentDocumentLink cdl : links) {
        Id versionId = cdl.ContentDocument.LatestPublishedVersionId;
        versionIds.add(versionId);
        versionIdToTitle.put(versionId, cdl.ContentDocument.Title);
    }

    // Stap 2: Haal alle ContentDistributions op voor deze versie-IDs
    Map<Id, String> versionIdToPublicUrl = new Map<Id, String>();
    for (ContentDistribution dist : [
        SELECT ContentVersionId, DistributionPublicUrl
        FROM ContentDistribution
        WHERE ContentVersionId IN :versionIds
    ]) {
        versionIdToPublicUrl.put(dist.ContentVersionId, dist.DistributionPublicUrl);
    }

    // Stap 3: Bouw de wrappers
    List<FileWrapper> result = new List<FileWrapper>();
    for (Id versionId : versionIds) {
        String title = versionIdToTitle.get(versionId);
        String url = versionIdToPublicUrl.get(versionId);

        if (String.isNotBlank(url)) {
            result.add(new FileWrapper(title, url));
        }
    }

    return result;
}
}