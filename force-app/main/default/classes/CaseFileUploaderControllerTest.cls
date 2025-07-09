@isTest
private class CaseFileUploaderControllerTest {
    @isTest
    static void testUploadFileToCase() {
        // Maak test Case aan
        Case testCase = new Case(Subject = 'Test Case for File Upload');
        insert testCase;
        System.debug('Test Case ID: ' + testCase.Id);

        // Simuleer bestand: "Testbestandinhoud" → base64
        String fileName = 'testfile.txt';
        String fileContent = 'Testbestandinhoud';
        String base64Content = EncodingUtil.base64Encode(Blob.valueOf(fileContent));
        System.debug('Test base64 content: ' + base64Content);

        Test.startTest();
        String publicUrl = CaseFileUploaderController.uploadFileToCase(testCase.Id, base64Content, fileName);
        Test.stopTest();

        System.debug('Gegenereerde publieke URL: ' + publicUrl);

        // Verifieer of public URL niet leeg is
        System.assertNotEquals(null, publicUrl, 'Public URL should not be null');
        System.assert(publicUrl.startsWith('http'), 'Public URL should be valid');
    }
}