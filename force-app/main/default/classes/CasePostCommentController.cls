public without sharing class CasePostCommentController {

    @AuraEnabled
public static void createFeedItem(Id recordId, String ignoredTitle, String body) {
    if (recordId == null || String.isBlank(body)) {
        throw new AuraHandledException('RecordId en bericht zijn verplicht.');
    }

    // FeedItem aanmaken
    FeedItem post = new FeedItem(
        ParentId   = recordId,
        Body       = body.trim(),
        Type       = 'TextPost',
        Visibility = 'AllUsers'
    );
    insert post;

    // Case ophalen + check status
    Case c = [
        SELECT Id, Status, Subject, CaseNumber, OwnerId, Owner.FirstName, Owner.Email,
               Account.Name, Aanmelder__r.FirstName, Aanmelder__r.Name, Reopened__c, Behandelaarsgroep__c
        FROM Case
        WHERE Id = :recordId
        FOR UPDATE
    ];

    Boolean isClosed = (c.Status == 'Closed');
    Boolean mailNodig = true;

    if (isClosed) {
        // Case heropenen en doorsturen naar behandelaarsgroep
        c.Status = 'In Progress';
        c.Reopened__c = true;

        if (c.Behandelaarsgroep__c != null) {
    Group behandelaars = [
        SELECT Id 
        FROM Group 
        WHERE Name = :c.Behandelaarsgroep__c 
          AND Type = 'Queue' 
        LIMIT 1
    ];
    c.OwnerId = behandelaars.Id;
}
    } else {
        c.Status = 'Response Received';
    }


    if (mailNodig && c.Owner.Email != null) {
        String onderwerp;
        String bodyText;
        String portalLink = 'https://farmad--sandbox2.sandbox.my.site.com/FOLPortaal/case/' + c.Id;

        if (isClosed) {
            onderwerp = c.Aanmelder__r.Name + ' (' + c.Account.Name + ') heeft gereageerd op een melding die jij hebt afgesloten (' +
                        c.CaseNumber + ') : ' + c.Subject;

            bodyText = 'Beste ' + c.Owner.FirstName + ',<br/><br/>' +
                c.Aanmelder__r.Name + ' (' + c.Account.Name + ') heeft gereageerd op een melding die jij hebt afgesloten (' +
                c.CaseNumber + ') : ' + c.Subject + '<br/><br/>' +
                '<strong>Reactie:</strong><br/>' +
                '<div style="background:#f3f3f3; padding:1em; border-left:4px solid #0070d2;">' +
                body.trim() + '</div><br/><br/>' +
                'Deze melding is terug geopend en op de algemene behandelaarsgroep geplaatst.<br/><br/>' +
                '<a href="' + portalLink + '" target="_blank">👉 Open deze melding in de portal</a><br/><br/>' +
                '--<br/>Ref: ' + c.CaseNumber;
        } else {
            onderwerp = c.Aanmelder__r.Name + ' (' + c.Account.Name + ') heeft een update geplaatst op melding ' +
                        '(ref. ' + c.CaseNumber + ') : ' + c.Subject;

            bodyText = 'Beste ' + c.Owner.FirstName + ',<br/><br/>' +
                'De aanmelder <strong>' + c.Aanmelder__r.Name + '</strong> heeft via het portaal een update geplaatst op melding <strong>' +
                c.CaseNumber + '</strong>:<br/><br/>' +
                '<div style="background:#f3f3f3; padding:1em; border-left:4px solid #0070d2;">' +
                body.trim() + '</div>' +
                '<br/><br/>Bekijk de melding in Salesforce om te antwoorden.<br/><br/>' +
                '<a href="https://farmad.lightning.force.com/lightning/r/Case/' + c.Id + '/view" target="_blank">' +
                '👉 Open deze case in Salesforce</a>' +
                '<br/><br/>--<br/>Ref: ' + c.CaseNumber;
        }

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { c.Owner.Email });
        mail.setSubject(onderwerp);
        mail.setHtmlBody(bodyText);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
update c;
}

    @AuraEnabled(cacheable=true)
    public static List<CaseComment> getComments(Id caseId) {
        return [
            SELECT Id,
                   CommentBody,
                   CreatedBy.Name,
                   CreatedDate
              FROM CaseComment
             WHERE ParentId = :caseId
             ORDER BY CreatedDate DESC
        ];
    }
}