public with sharing class PortalUserCasesController {
    @AuraEnabled(cacheable=true)
    public static List<Case> getPortalUserCases() {
        try {
            Id userId = UserInfo.getUserId();
            Id contactId = [SELECT ContactId FROM User WHERE Id = :userId LIMIT 1].ContactId;
            Id accountId = [SELECT AccountId FROM Contact WHERE Id = :contactId LIMIT 1].AccountId;

            List<Case> cases = [
                SELECT Id, CaseNumber, Subject, Description,
                       Aanmelder__c, Aanmelder__r.Name, Status,
                       CreatedDate, Contact.Name, Date_Time_target__c,Owner.Name,
                       Owner.FirstName, Owner.LastName
                FROM Case 
                WHERE AccountId = :accountId
                ORDER BY CreatedDate DESC
                LIMIT 50
            ];

            return cases;
        } catch (Exception e) {
            throw new AuraHandledException('Fout bij ophalen cases: ' + e.getMessage());
        }
    }
}