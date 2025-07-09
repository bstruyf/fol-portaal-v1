@isTest
public with sharing class OpenAITest {
    @AuraEnabled
    public static String testCallout() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:OpenAI/v1/models');
        req.setMethod('GET');
        Http http = new Http();
        HttpResponse res = http.send(req);
        return res.getBody();
    }
}