public with sharing class OpenAISubcategorySuggester {

    private static final String OPENAI_API_KEY = 'Bearer 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'; // vervang met je eigen key

    public class AIResponseWrapper {
        @AuraEnabled public String raw;
    }

    @AuraEnabled
    public static AIResponseWrapper getRawAIResponse(String description) {
        System.debug('📌 getRawAIResponse gestart');

        // 🔎 Stap 1: haal unieke subcategorieën op uit het object Category__c
Set<String> subcategoriesSet = new Set<String>();
for (Category__c cat : [SELECT SubCategory__c FROM Category__c WHERE SubCategory__c != null]) {
    subcategoriesSet.add(cat.SubCategory__c);
}
List<String> subcategories = new List<String>(subcategoriesSet);
subcategories.sort();


        // 🔹 Stap 2: bouw prompt waarin GPT enkel mag kiezen uit bestaande subcategorieën
        String lijst = String.join(subcategories, ', ');
        String prompt =
            'Kies uit deze subcategorieën: ' + lijst + '.\n' +
            'Geef de 3 meest relevante subcategorieën voor de volgende caseomschrijving:\n' +
            '"' + description + '"\n' +
            'Geef enkel een komma-gescheiden lijst terug zoals:\n' +
            'Toegang, Foutmelding, Beheer';

        // 🔧 Stap 3: bouw en verzend API-verzoek
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.openai.com/v1/chat/completions');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', OPENAI_API_KEY);
        req.setTimeout(10000);

        req.setBody(JSON.serialize(new Map<String, Object>{
            'model' => 'gpt-3.5-turbo',
            'messages' => new List<Object>{
                new Map<String, String>{
                    'role' => 'user',
                    'content' => prompt
                }
            },
            'temperature' => 0.4
        }));

        String result = 'GEEN ANTW';

        try {
            Http http = new Http();
            HttpResponse res = http.send(req);
            System.debug('📡 Status: ' + res.getStatusCode());
            System.debug('📨 Body: ' + res.getBody());

            if (res.getStatusCode() == 200) {
                Map<String, Object> bodyMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> choices = (List<Object>) bodyMap.get('choices');
                if (!choices.isEmpty()) {
                    Map<String, Object> firstChoice = (Map<String, Object>) choices[0];
                    Map<String, Object> message = (Map<String, Object>) firstChoice.get('message');
                    result = (String) message.get('content');
                }
            } else {
                result = 'FOUT: HTTP ' + res.getStatusCode();
            }
        } catch (Exception e) {
            System.debug('❌ Fout tijdens callout: ' + e.getMessage());
            result = 'FOUT: ' + e.getMessage();
        }

        AIResponseWrapper wrapper = new AIResponseWrapper();
        wrapper.raw = result;
        return wrapper;
    }
}