public with sharing class AccountCasesController {
    @AuraEnabled(cacheable=true)
    public static List<Case> getAccountCases() {
        try {
            // Haal de ingelogde gebruiker op
            Id userId = UserInfo.getUserId();
            
            // Zoek de ContactId van de ingelogde gebruiker
            User currentUser = [SELECT ContactId FROM User WHERE Id = :userId LIMIT 1];

            if (currentUser.ContactId == null) {
                throw new AuraHandledException('Geen gekoppeld Contact gevonden voor deze gebruiker.');
            }

            // Haal de AccountIds op uit de AccountContactRelation tabel
            List<AccountContactRelation> accountRelations = [
                SELECT AccountId FROM AccountContactRelation 
                WHERE ContactId = :currentUser.ContactId AND IsActive = true
            ];

            if (accountRelations.isEmpty()) {
                throw new AuraHandledException('Geen gekoppelde Accounts gevonden voor dit Contact.');
            }

            // Zet alle gevonden AccountIds in een Set (voor efficiëntere query)
            Set<Id> accountIds = new Set<Id>();
            for (AccountContactRelation relation : accountRelations) {
                accountIds.add(relation.AccountId);
            }

            // Haal alle cases op die bij de gevonden Accounts horen
            List<Case> cases = [SELECT Id, CaseNumber, Subject, Status, CreatedDate 
                                FROM Case 
                                WHERE AccountId IN :accountIds
                                ORDER BY CreatedDate DESC
                                LIMIT 50];

            return cases;
        } catch (Exception e) {
            throw new AuraHandledException('Fout bij ophalen cases: ' + e.getMessage());
        }
    }
}