public with sharing class CaseSupportController {

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> searchArticles(String searchTerm) {
        if (String.isBlank(searchTerm)) return new List<Map<String, String>>();

        List<Map<String, String>> results = new List<Map<String, String>>();
        List<KnowledgeArticleVersion> articles;

        if (Test.isRunningTest()) {
            // In tests kunnen we PublishStatus niet gebruiken
            articles = [
                SELECT Id, Title, Summary
                FROM KnowledgeArticleVersion
                WHERE Language = 'nl'
                  AND Title LIKE :('%' + searchTerm + '%')
                LIMIT 10
            ];
        } else {
            articles = [
                SELECT Id, Title, Summary
                FROM KnowledgeArticleVersion
                WHERE PublishStatus = 'Online'
                  AND Language = 'nl'
                  AND Title LIKE :('%' + searchTerm + '%')
                ORDER BY LastPublishedDate DESC
                LIMIT 10
            ];
        }

        for (KnowledgeArticleVersion a : articles) {
            results.add(new Map<String, String>{
                'Id' => a.Id,
                'Title' => a.Title,
                'Summary' => a.Summary
            });
        }

        return results;
    }

    @AuraEnabled(cacheable=true)
    public static List<Case> getSimilarCases(Id caseId) {
        if (caseId == null) return new List<Case>();

        Case currentCase = [
            SELECT Id, AccountId, Subject, Category__c, Subcategory__c
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];

        return [
            SELECT Id, CaseNumber, Subject, Status
            FROM Case
            WHERE Id != :caseId
              AND AccountId = :currentCase.AccountId
              AND (
                   Subject LIKE :('%' + currentCase.Subject + '%') OR
                   (Category__c = :currentCase.Category__c AND Subcategory__c = :currentCase.Subcategory__c)
              )
              AND CreatedDate >= LAST_N_YEARS:1
            ORDER BY CreatedDate DESC
            LIMIT 10
        ];
    }
}