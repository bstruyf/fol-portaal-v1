public with sharing class FilePasteUploaderController {
    @AuraEnabled
    public static Id uploadFile(String fileName, String base64Data) {
        try {
            ContentVersion cv = new ContentVersion();
            cv.Title = fileName;
            cv.PathOnClient = fileName;
            cv.VersionData = EncodingUtil.base64Decode(base64Data);
            insert cv;
            return cv.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Fout bij uploaden bestand: ' + e.getMessage());
        }
    }
}