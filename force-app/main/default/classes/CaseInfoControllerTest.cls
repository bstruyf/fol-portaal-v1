@isTest
private class CaseInfoControllerTest {

    @isTest
    static void testGetCaseInfoWithoutCustomFields() {
        // 1. Maak een test-case aan met alleen standaardvelden
        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Origin = 'Web',
            Type = 'Incident'
        );
        insert testCase;

        // 2. Roep de Apex-methode aan
        Test.startTest();
        Case result = CaseInfoController.getCaseInfo(testCase.Id);
        Test.stopTest();

        // 3. Controleer het resultaat
        System.assertNotEquals(null, result, 'Resultaat mag niet null zijn');
        System.assertEquals(testCase.Id, result.Id, 'Id moet overeenkomen');
        System.assertEquals('Test Case', result.Subject);
    }
}