public with sharing class PasteScreenshotUploaderController {
    @AuraEnabled
    public static void uploadFile(String fileName, String base64Data, Id recordId) {
        try {
            ContentVersion cv = new ContentVersion();
            cv.Title = fileName;
            cv.PathOnClient = fileName;
            cv.VersionData = EncodingUtil.base64Decode(base64Data);
            cv.FirstPublishLocationId = recordId;
            insert cv;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}