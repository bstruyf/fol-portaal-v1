@isTest
public class FilePasteUploaderControllerTest {
    
    @isTest
    public static void testUploadFile() {
        // Testgegevens
        String testFileName = 'TestBestand.png';
        String testBase64Data = EncodingUtil.base64Encode(Blob.valueOf('Testbestand inhoud'));

        // Start testcontext
        Test.startTest();
        Id contentVersionId = FilePasteUploaderController.uploadFile(testFileName, testBase64Data);
        Test.stopTest();

        // Validaties
        System.assertNotEquals(null, contentVersionId, 'ContentVersion ID mag niet null zijn');

        // Ophalen van het ContentVersion record en controleren van de waarden
        ContentVersion cv = [SELECT Id, Title, PathOnClient FROM ContentVersion WHERE Id = :contentVersionId LIMIT 1];

        System.assertEquals(testFileName, cv.Title, 'De bestandsnaam moet overeenkomen');
        System.assertEquals(testFileName, cv.PathOnClient, 'De PathOnClient moet overeenkomen');
    }
}