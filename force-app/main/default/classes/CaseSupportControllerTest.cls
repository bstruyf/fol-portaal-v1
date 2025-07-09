@isTest
public class CaseSupportControllerTest {

    @testSetup
    static void setupData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Case c1 = new Case(
            Subject = 'Printer werkt niet',
            AccountId = acc.Id,
            Category__c = 'Hardware',
            Subcategory__c = 'Printer'
        );
        insert c1;

        Case c2 = new Case(
            Subject = 'Printer maakt lawaai',
            AccountId = acc.Id,
            Category__c = 'Hardware',
            Subcategory__c = 'Printer'
        );
        insert c2;
    }

    @isTest
    static void testGetSimilarCases() {
        Case ref = [SELECT Id FROM Case WHERE Subject = 'Printer werkt niet' LIMIT 1];

        Test.startTest();
        List<Case> similar = CaseSupportController.getSimilarCases(ref.Id);
        Test.stopTest();

        System.assert(similar.size() > 0, 'Er moeten vergelijkbare cases zijn');
    }

    @isTest
    static void testSearchArticlesMock() {
        Test.startTest();
        List<Map<String, String>> result = CaseSupportController.searchArticles('wachtwoord');
        Test.stopTest();

        // Je krijgt in de testcontext altijd een lege lijst terug, dat is OK
        System.assert(result != null, 'Resultaat mag niet null zijn');
    }
}