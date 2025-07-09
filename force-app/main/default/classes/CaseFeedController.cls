public without sharing class CaseFeedController {

    public class UnifiedFeedItem {
        @AuraEnabled public String id;
        @AuraEnabled public String type;
        @AuraEnabled public String actorId;
        @AuraEnabled public String actorName;
        @AuraEnabled public String createdDate;
        @AuraEnabled public String content;     // Plain text óf HTML-body van e-mail
        @AuraEnabled public String title;       // Bij e-mail: het Subject
        @AuraEnabled public String versionId;   // Voor bijlagen: ContentVersion Id
@AuraEnabled public String publicUrl;   // Publieke link indien beschikbaar
    }

    @AuraEnabled(cacheable=true)
    public static List<UnifiedFeedItem> getCaseFeed(Id caseId) {
        // 1) Haal Case + contact/aanmelder op
        Case c = [
            SELECT Id,
                   CreatedDate,
                   CreatedById,
                   CreatedBy.FirstName,
                   CreatedBy.LastName,
                   ContactId,
                   Aanmelder__c,
                   Aanmelder__r.Name
              FROM Case
             WHERE Id = :caseId
        ];
        List<UnifiedFeedItem> unified = new List<UnifiedFeedItem>();

        // 1a) Case-created event
        UnifiedFeedItem creation = new UnifiedFeedItem();
        creation.id          = c.Id + '_created';
        creation.type        = 'CaseCreated';
        creation.actorId     = c.CreatedById;
        creation.actorName   = (c.CreatedBy.FirstName != null)
                                 ? c.CreatedBy.FirstName + ' ' + c.CreatedBy.LastName
                                 : c.Aanmelder__r.Name;
        creation.createdDate = String.valueOf(c.CreatedDate);
        creation.title       = 'Case created';
        creation.content     = null;
        creation.versionId   = null;
        unified.add(creation);

        // 2) Chatter‐berichten
      for (FeedItem fi : [
    SELECT Id,
           Body,
           Title,
           CreatedDate,
           CreatedById,
           CreatedBy.FirstName,
           CreatedBy.LastName,
           Type,
           Visibility
      FROM FeedItem
     WHERE ParentId = :caseId
       AND Type != 'EmailMessageEvent'
       AND Visibility = 'AllUsers'
]) {
            if (String.isBlank(fi.Body)) continue;
            UnifiedFeedItem item = new UnifiedFeedItem();
            item.id    = fi.Id;
            item.type  = 'Chatter';

            if (String.isBlank(fi.CreatedBy.FirstName)) {
                item.actorId   = c.Aanmelder__c;
                item.actorName = c.Aanmelder__r.Name;
            } else {
                item.actorId   = fi.CreatedById;
                item.actorName = fi.CreatedBy.FirstName + ' ' + fi.CreatedBy.LastName;
            }

            item.createdDate = String.valueOf(fi.CreatedDate);
            item.content     = fi.Body;
            item.title       = fi.Title;
            item.versionId   = null;
            unified.add(item);
        }

        // 3) E-mails (nu met HtmlBody)
        for (EmailMessage em : [
            SELECT Id,
                   Subject,
                   FromName,
                   CreatedDate,
                   TextBody,
                   HtmlBody
              FROM EmailMessage
             WHERE ParentId = :caseId
        ]) {
            UnifiedFeedItem item = new UnifiedFeedItem();
            item.id          = em.Id;
            item.type        = 'Email';
            item.actorId     = null;
            item.actorName   = em.FromName;
            item.createdDate = String.valueOf(em.CreatedDate);
            // gebruik HTML-body als die er is, anders fallback naar TextBody
            item.content     = (em.HtmlBody != null ? em.HtmlBody : em.TextBody);
            // zet het e-mail Subject als titel, zodat je het in de feed makkelijk kunt tonen
            item.title       = em.Subject;
            item.versionId   = null;
            unified.add(item);
        }

        // 4) Taken
       
        // 5) Bijlagen
         // 5) Bijlagen
List<ContentDocumentLink> links = [
    SELECT ContentDocumentId,
           ContentDocument.Title,
           ContentDocument.LatestPublishedVersionId,
           ContentDocument.CreatedDate
      FROM ContentDocumentLink
     WHERE LinkedEntityId = :caseId
];

Set<Id> versionIds = new Set<Id>();
for (ContentDocumentLink cdl : links) {
    if (cdl.ContentDocument.LatestPublishedVersionId != null) {
        versionIds.add(cdl.ContentDocument.LatestPublishedVersionId);
    }
}

Map<Id, ContentDistribution> distributions = new Map<Id, ContentDistribution>();
if (!versionIds.isEmpty()) {
    for (ContentDistribution dist : [
        SELECT ContentVersionId, DistributionPublicUrl
          FROM ContentDistribution
         WHERE ContentVersionId IN :versionIds
    ]) {
        distributions.put(dist.ContentVersionId, dist);
    }
}

for (ContentDocumentLink cdl : links) {
    UnifiedFeedItem item = new UnifiedFeedItem();
    item.id          = cdl.ContentDocumentId;
    item.type        = 'Bijlage';
    item.actorId     = c.CreatedById;
    item.actorName   = (c.CreatedBy.FirstName != null)
                         ? c.CreatedBy.FirstName + ' ' + c.CreatedBy.LastName
                         : c.Aanmelder__r.Name;
    item.createdDate = String.valueOf(cdl.ContentDocument.CreatedDate);
    item.content     = null;
    item.title       = cdl.ContentDocument.Title;
    item.versionId   = cdl.ContentDocument.LatestPublishedVersionId;
    item.publicUrl   = distributions.containsKey(cdl.ContentDocument.LatestPublishedVersionId)
                     ? distributions.get(cdl.ContentDocument.LatestPublishedVersionId).DistributionPublicUrl
                     : null;

    unified.add(item);
}
        // 6) Afspraken
        for (Event e : [
            SELECT Id,
                   Subject,
                   OwnerId,
                   Owner.FirstName,
                   Owner.LastName,
                   CreatedDate,
                   Description,
                   StartDateTime,
                   EndDateTime
              FROM Event
             WHERE WhatId = :caseId
             ORDER BY CreatedDate DESC
        ]) {
            UnifiedFeedItem item = new UnifiedFeedItem();
            item.id          = e.Id;
            item.type        = 'Afspraak';
            item.actorId     = e.OwnerId;
            item.actorName   = e.Owner.FirstName + ' ' + e.Owner.LastName;
            item.createdDate = String.valueOf(e.CreatedDate);

            String tijdInfo = '';
            if (e.StartDateTime != null) {
                tijdInfo += 'datum: ' + formatDatum(e.StartDateTime)
                         + ' om ' + formatTijd(e.StartDateTime);
            }
            if (e.EndDateTime != null) {
                tijdInfo += ' tot ' + formatTijd(e.EndDateTime) + ' u.';
            }
            item.content     = e.Subject
                             + '\n' + tijdInfo
                             + (e.Description != null ? '\n' + e.Description : '');
            item.title       = null;
            item.versionId   = null;
            unified.add(item);
        }

        // 7) Sorteer op datum (nieuwste eerst)
        unified.sort(new SortByCreatedDateDesc());
        return unified;
    }

    private static String formatDatum(DateTime dt) {
        Date d = dt.date();
        return pad2(d.day()) + '/' + pad2(d.month()) + '/' + d.year();
    }

    private static String formatTijd(DateTime dt) {
        Time t = dt.time();
        return pad2(t.hour()) + ':' + pad2(t.minute());
    }

    private static String pad2(Integer val) {
        return (val < 10 ? '0' : '') + String.valueOf(val);
    }

    public class SortByCreatedDateDesc implements Comparator<UnifiedFeedItem> {
        public Integer compare(UnifiedFeedItem a, UnifiedFeedItem b) {
            Long diff = DateTime.valueOf(b.createdDate).getTime()
                      - DateTime.valueOf(a.createdDate).getTime();
            return diff > 0 ? 1 : (diff < 0 ? -1 : 0);
        }
    }
}