public without sharing class CaseFileUploader {

    @AuraEnabled
    public static void addFileToCase(Id caseId, Id contentDocumentId) {
        try {
            // Maak een ContentDocumentLink aan om het bestand aan de case te koppelen
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = contentDocumentId;
            cdl.LinkedEntityId = caseId;  // Verbind het bestand aan de Case
            cdl.ShareType = 'V';  // Het bestand is zichtbaar voor de eigenaar van de case
            cdl.Visibility = 'AllUsers';  // Bestanden kunnen zichtbaar zijn voor alle gebruikers
            insert cdl;
        } catch (Exception e) {
            throw new AuraHandledException('Fout bij het koppelen van het bestand aan de case: ' + e.getMessage());
        }
    }
}