public with sharing class CaseViewerController {

    @AuraEnabled(cacheable=true)
    public static ViewerWrapper getCurrentViewer(Id caseId) {
        if (caseId == null) {
            System.debug('⚠️ getCurrentViewer: caseId is null');
            return null;
        }

        System.debug('▶️ getCurrentViewer aangeroepen door userId: ' + UserInfo.getUserId() + ' voor caseId: ' + caseId);

        List<Case_View__c> records = [
            SELECT Id, User__r.Name, User__c, LastViewedAt__c
            FROM Case_View__c
            WHERE Case__c = :caseId AND IsActive__c = true
            ORDER BY LastViewedAt__c DESC
            LIMIT 1
        ];

        if (records.isEmpty()) {
            System.debug('📭 Geen actieve viewers gevonden.');
            return null;
        }

        Case_View__c existing = records[0];
        System.debug('📌 Actieve viewer gevonden: ' + existing.User__r.Name + ' op ' + existing.LastViewedAt__c);

        Boolean isCurrent = existing.User__c == UserInfo.getUserId();
        Boolean isRecent = existing.LastViewedAt__c != null &&
            DateTime.now().getTime() - existing.LastViewedAt__c.getTime() < 2 * 60 * 1000;

        System.debug('🔍 isCurrent: ' + isCurrent + ' | isRecent: ' + isRecent);

        return new ViewerWrapper(existing.User__c, existing.User__r.Name, isCurrent || !isRecent);
    }

    @AuraEnabled
    public static void registerViewer(Id caseId) {
        if (caseId == null) {
            System.debug('⚠️ registerViewer: caseId is null');
            return;
        }

        System.debug('🟢 registerViewer aangeroepen door userId: ' + UserInfo.getUserId() + ' voor caseId: ' + caseId);

        List<Case_View__c> existing = [
            SELECT Id
            FROM Case_View__c
            WHERE Case__c = :caseId AND User__c = :UserInfo.getUserId()
            LIMIT 1
        ];

        Case_View__c view;
        if (existing.isEmpty()) {
            view = new Case_View__c(Case__c = caseId, User__c = UserInfo.getUserId());
            System.debug('🆕 Nieuw Case_View__c record wordt aangemaakt.');
        } else {
            view = existing[0];
            System.debug('✏️ Bestaand Case_View__c record wordt bijgewerkt: ' + view.Id);
        }

        view.LastViewedAt__c = DateTime.now();
        view.IsActive__c = true;

        upsert view;
        System.debug('✅ Case_View__c record opgeslagen (insert/update).');
    }

    @AuraEnabled
    public static void unregisterViewer(Id caseId) {
        if (caseId == null) {
            System.debug('⚠️ unregisterViewer: caseId is null');
            return;
        }

        System.debug('🔻 unregisterViewer aangeroepen door userId: ' + UserInfo.getUserId() + ' voor caseId: ' + caseId);

        List<Case_View__c> records = [
            SELECT Id, IsActive__c
            FROM Case_View__c
            WHERE Case__c = :caseId AND User__c = :UserInfo.getUserId()
        ];

        if (records.isEmpty()) {
            System.debug('📭 Geen Case_View__c records gevonden om af te melden.');
            return;
        }

        for (Case_View__c rec : records) {
            rec.IsActive__c = false;
        }

        update records;
        System.debug('🛑 Case_View__c records gedeactiveerd: ' + records.size());
    }

    public class ViewerWrapper {
        @AuraEnabled public String userId;
        @AuraEnabled public String userName;
        @AuraEnabled public Boolean isCurrentUser;

        public ViewerWrapper(String userId, String userName, Boolean isCurrentUser) {
            this.userId = userId;
            this.userName = userName;
            this.isCurrentUser = isCurrentUser;
        }
    }
@AuraEnabled(cacheable=true)
public static List<String> getActiveViewers(Id caseId) {
    if (caseId == null) {
        System.debug('⚠️ getActiveViewers: caseId is null');
        return new List<String>();
    }

    System.debug('📣 getActiveViewers aangeroepen door userId: ' + UserInfo.getUserId() + ' voor caseId: ' + caseId);

    List<Case_View__c> records = [
        SELECT User__r.Name
        FROM Case_View__c
        WHERE Case__c = :caseId
          AND IsActive__c = true
          AND User__c != :UserInfo.getUserId()
    ];

    List<String> names = new List<String>();
    for (Case_View__c rec : records) {
        if (rec.User__r != null) {
            names.add(rec.User__r.Name);
        }
    }

    System.debug('👀 Andere actieve viewers: ' + String.join(names, ', '));
    return names;
}
}