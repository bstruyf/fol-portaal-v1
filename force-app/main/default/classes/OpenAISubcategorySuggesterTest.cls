@isTest
public class OpenAISubcategorySuggesterTest {

    @isTest static void testSuggestFromCase() {
        // Dummy Case record aanmaken
        Case testCase = new Case(
            Subject = 'Test AI suggestie',
            Description = 'De software toont een foutmelding bij het opstarten.'
        );
        insert testCase;
        System.debug('Case aangemaakt met Id: ' + testCase.Id);

        // Wrapper vullen
        OpenAISubcategorySuggester.CaseWrapper wrapper = new OpenAISubcategorySuggester.CaseWrapper();
        wrapper.caseId = testCase.Id;
        List<OpenAISubcategorySuggester.CaseWrapper> input = new List<OpenAISubcategorySuggester.CaseWrapper>{ wrapper };

        Test.startTest();
        List<OpenAISubcategorySuggester.ResponseWrapper> result = OpenAISubcategorySuggester.suggestFromCase(input);
        Test.stopTest();

        // Debug output
        System.debug('Suggestie-output van AI: ' + result);

        // Asserties
        System.assertNotEquals(null, result, 'Result mag niet null zijn');
        System.assertEquals(1, result.size(), 'Er moet exact 1 ResponseWrapper zijn');
        System.assert(result[0].suggestions.size() > 0, 'Suggesties mogen niet leeg zijn');
    }
}