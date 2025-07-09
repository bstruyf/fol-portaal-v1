@isTest
private class OpenAITest_Test {

    // 🔹 Mockclass voor Named Credential callout
    class OpenAIMockResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"data":[{"id":"gpt-3.5-turbo","object":"model"}]}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest static void testCalloutSuccess() {
        // Zet mock response
        Test.setMock(HttpCalloutMock.class, new OpenAIMockResponse());

        Test.startTest();
        String result = OpenAITest.testCallout();
        Test.stopTest();

        System.debug('✅ Response van testCallout(): ' + result);

        System.assert(result.contains('gpt-3.5-turbo'), 'Response moet model ID bevatten');
    }
}