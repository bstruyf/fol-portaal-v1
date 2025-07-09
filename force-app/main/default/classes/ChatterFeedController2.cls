public without sharing class ChatterFeedController2 {

    public class UnifiedFeedItem {
        @AuraEnabled public String id;
        @AuraEnabled public String type;
        @AuraEnabled public String actorId;
        @AuraEnabled public String actorName;
        @AuraEnabled public String createdDate;
        @AuraEnabled public String content;
        @AuraEnabled public String title;
    }

    @AuraEnabled(cacheable=true)
    public static List<UnifiedFeedItem> getChatterFeed(Id caseId) {
        System.debug('📣 [ChatterFeed2] Start ophalen chatterfeed voor caseId: ' + caseId);

        Case c = [
            SELECT Id, CreatedById, CreatedBy.FirstName, CreatedBy.LastName,
                   Aanmelder__c, Aanmelder__r.Name
              FROM Case
             WHERE Id = :caseId
             LIMIT 1
        ];

        List<FeedItem> feedItems = [
            SELECT Id, Body, Title, CreatedDate, CreatedById, CreatedBy.FirstName, CreatedBy.LastName
              FROM FeedItem
             WHERE ParentId = :caseId
             ORDER BY CreatedDate DESC
             LIMIT 20
        ];

        List<UnifiedFeedItem> result = new List<UnifiedFeedItem>();

        for (FeedItem fi : feedItems) {
            UnifiedFeedItem item = new UnifiedFeedItem();
            item.id = fi.Id;
            item.type = 'Chatter';
            item.title = fi.Title;
            item.createdDate = String.valueOf(fi.CreatedDate);

            item.actorId = String.isBlank(fi.CreatedBy.FirstName)
                ? c.Aanmelder__c
                : fi.CreatedById;

            item.actorName = String.isBlank(fi.CreatedBy.FirstName)
                ? c.Aanmelder__r.Name
                : fi.CreatedBy.FirstName + ' ' + fi.CreatedBy.LastName;

            String html = fi.Body != null ? fi.Body : '';
            List<String> links = new List<String>();

            Pattern p = Pattern.compile('sfdc://([a-zA-Z0-9]{15,18})');
            Matcher m = p.matcher(html);

            while (m.find()) {
                String versionId = m.group(1);
                String url = '/sfc/servlet.shepherd/version/download/' + versionId;
                System.debug('🔗 [ChatterFeed2] Afbeelding gevonden in ' + fi.Id + ': ' + versionId + ' → ' + url);
                links.add('<a href="' + url + '" target="_blank">' + versionId + '</a>');
            }

            if (!links.isEmpty()) {
                html += '<div class="slds-m-top_small"><b>Afbeeldingen:</b><br/>' + String.join(links, '<br/>') + '</div>';
            }

            item.content = html;
            result.add(item);
        }

        linkAttachmentsToCase(caseId);

        System.debug('📣 [ChatterFeed2] Aantal feeditems opgebouwd: ' + result.size());
        return result;
    }

    private static void linkAttachmentsToCase(Id caseId) {
        // Stap 1: Haal alle FeedItem Id's op
        List<Id> feedItemIds = new List<Id>();
        for (FeedItem fi : [
            SELECT Id FROM FeedItem WHERE ParentId = :caseId
        ]) {
            feedItemIds.add(fi.Id);
        }

        if (feedItemIds.isEmpty()) {
            System.debug('📣 [ChatterFeed2] Geen feeditems gevonden voor caseId ' + caseId);
            return;
        }

        // Stap 2: Haal bestaande links op voor Case
        Set<Id> reedsGelinkt = new Set<Id>();
        for (ContentDocumentLink cdl : [
            SELECT ContentDocumentId
              FROM ContentDocumentLink
             WHERE LinkedEntityId = :caseId
        ]) {
            reedsGelinkt.add(cdl.ContentDocumentId);
        }

        // Stap 3: Zoek extra bijlagen van de FeedItems
        List<ContentDocumentLink> nieuwTeKoppelen = new List<ContentDocumentLink>();

        for (ContentDocumentLink cdl : [
            SELECT ContentDocumentId
              FROM ContentDocumentLink
             WHERE LinkedEntityId IN :feedItemIds
        ]) {
            if (!reedsGelinkt.contains(cdl.ContentDocumentId)) {
                nieuwTeKoppelen.add(new ContentDocumentLink(
                    ContentDocumentId = cdl.ContentDocumentId,
                    LinkedEntityId = caseId,
                    ShareType = 'V',
                    Visibility = 'AllUsers'
                ));
            }
        }

        if (!nieuwTeKoppelen.isEmpty()) {
            insert nieuwTeKoppelen;
            System.debug('📣 [ChatterFeed2] ' + nieuwTeKoppelen.size() + ' bijlagen gekoppeld aan case: ' + caseId);
        } else {
            System.debug('📣 [ChatterFeed2] Geen nieuwe bijlagen om te koppelen.');
        }
    }
}