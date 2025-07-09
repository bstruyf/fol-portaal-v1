public with sharing class CaseEmailController {

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getCaseData(Id caseId) {
        // Haal user info op voor handtekening
        User currentUser = [
            SELECT Name, Title, Email, Phone
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        // Haal case info
        Case c = [
            SELECT Id, Subject, CaseNumber, Account.Name, Contact.Email,
                   MailToAanmelder__c, Aanmelder__r.Email, Aanmelder__r.FirstName,
                   Aanmelder__r.Name, Aanmelder__r.Id, Description2__c
            FROM Case
            WHERE Id = :caseId
        ];

        List<String> recipients = new List<String>();
        if (c.Contact != null && String.isNotBlank(c.Contact.Email)) {
            recipients.add(c.Contact.Email);
        }
        if (c.MailToAanmelder__c && c.Aanmelder__r != null && String.isNotBlank(c.Aanmelder__r.Email)) {
            recipients.add(c.Aanmelder__r.Email);
        }

        return new Map<String, Object>{
            'accountName'        => c.Account != null ? c.Account.Name : 'Onbekend',
            'shortDescription'   => c.Subject,
            'caseNumber'         => c.CaseNumber,
            'toRecipients'       => recipients,
            'fromAddress'        => currentUser.Email,
            'mailToAanmelder'    => c.MailToAanmelder__c,
            'aanmelderNaam'      => c.Aanmelder__r != null ? c.Aanmelder__r.Name : 'Onbekend',
            'aanmelderVoornaam'  => c.Aanmelder__r != null ? c.Aanmelder__r.FirstName : 'klant',
            'aanmelderId'        => c.Aanmelder__r != null ? c.Aanmelder__r.Id : null,
            'aanmelderName'      => c.Aanmelder__r != null ? c.Aanmelder__r.Name : null,
            'userName'           => currentUser.Name,
            'userTitle'          => currentUser.Title,
            'userEmail'          => currentUser.Email,
            'userPhone'          => currentUser.Phone,
			'description2__c'     => c.Description2__c
        };
    }

    @AuraEnabled
public static void sendCaseEmail(Id caseId, String subject, String body, String feedMessage, Boolean closeCase, Boolean internalOnly) {
    Case c = [
        SELECT Id, Contact.Email, MailToAanmelder__c, Aanmelder__r.Email
        FROM Case
        WHERE Id = :caseId
        FOR UPDATE
    ];

    List<String> recipients = new List<String>();
    if (c.Contact != null && String.isNotBlank(c.Contact.Email)) {
        recipients.add(c.Contact.Email);
    }
    if (c.MailToAanmelder__c && c.Aanmelder__r != null && String.isNotBlank(c.Aanmelder__r.Email)) {
        recipients.add(c.Aanmelder__r.Email);
    }

    // Alleen verzenden als niet intern
    if (!internalOnly) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(recipients);
        mail.setSubject(subject);
        mail.setHtmlBody(body);
        mail.setTargetObjectId(null);
        mail.setWhatId(c.Id);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

    // FeedItem aanmaken
    if (internalOnly && !String.isBlank(feedMessage)) {
        FeedItem post = new FeedItem();
        post.ParentId = caseId;
        post.Body = stripHtml(feedMessage);
        post.Type = 'TextPost';
        post.Visibility = internalOnly ? 'InternalUsers' : 'AllUsers';
        insert post;
    }

    // Case-status bijwerken
    c.OwnerId = UserInfo.getUserId();
    c.Status = closeCase ? 'Closed' : 'In Progress';
    update c;
}


@AuraEnabled
public static void createCaseEvent(
    Id caseId,
    String subject,
    String startDate,
    String startTime,
    String endDate,
    String endTime,
    Id whoId
) {
    try {
        // Stap 1: Case ophalen
        Case c = [
            SELECT Id
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];

        // Stap 2: Datum/tijd samenstellen
        DateTime startDateTime = DateTime.valueOf(startDate + ' ' + startTime + ':00');
DateTime endDateTime = DateTime.valueOf(endDate + ' ' + endTime + ':00');

        // Validaties
        if (endDateTime <= startDateTime) {
            throw new AuraHandledException('[DEBUG] Eindtijd <= Starttijd → Start: ' + startDateTime + ' / Eind: ' + endDateTime);
        }

        if (String.isBlank(subject)) {
            throw new AuraHandledException('[DEBUG] Leeg onderwerp');
        }

        if (whoId == null) {
            throw new AuraHandledException('[DEBUG] Geen WhoId ontvangen');
        }

        // Stap 3: Event aanmaken
        Event e = new Event();
        e.Subject = subject;
        e.StartDateTime = startDateTime;
        e.EndDateTime = endDateTime;
        e.WhatId = c.Id;
        e.WhoId = whoId;
        e.IsReminderSet = true;
        e.ReminderDateTime = startDateTime.addMinutes(-15);

        insert e;
String icsContent = 
    'BEGIN:VCALENDAR\n' +
    'VERSION:2.0\n' +
    'BEGIN:VEVENT\n' +
    'DTSTAMP:' + formatICSDateTime(System.now()) + '\n' +
    'DTSTART:' + formatICSDateTime(e.StartDateTime) + '\n' +
    'DTEND:' + formatICSDateTime(e.EndDateTime) + '\n' +
    'SUMMARY:' + e.Subject + '\n' +
    'DESCRIPTION:Afspraak met Farmad op ' + formatUserFriendlyDate(e.StartDateTime) + '\n' +
    'ORGANIZER:mailto:' + UserInfo.getUserEmail() + '\n' +
    'ATTENDEE:mailto:' + (e.WhoId != null ? getContactEmail(e.WhoId) : 'onbekend@farmad.be') + '\n' +
    'END:VEVENT\n' +
    'END:VCALENDAR';
    } catch (Exception ex) {
        // Debugdetails verzamelen
        String debugMessage = '[FOUT BIJ INSERT] → \n' +
    'CaseId=' + String.valueOf(caseId).left(18) + '\n' +
    'Subject=' + String.valueOf(subject).abbreviate(80) + '\n' +
    'Start=' + startDate + ' ' + startTime + '\n' +
    'Einde=' + endDate + ' ' + endTime + '\n' +
    'WhoId=' + String.valueOf(whoId).left(18) + '\n' +
    'Fout=' + ex.getMessage().abbreviate(50);

        throw new AuraHandledException(debugMessage);
    }
}
private static String formatICSDateTime(DateTime dt) {
    return dt.formatGmt('yyyyMMdd\'T\'HHmmss\'Z\'');
}
private static String formatUserFriendlyDate(DateTime dt) {
    return dt.format('dd/MM/yyyy HH:mm');
}
private static String getContactEmail(Id contactId) {
    Contact c = [SELECT Email FROM Contact WHERE Id = :contactId LIMIT 1];
    return c.Email;
}
private static String stripHtml(String input) {
    return input != null ? input.replaceAll('<[^>]+>', '') : null;
}
@AuraEnabled(cacheable=true)
public static List<QuickText> getQuickTexts(String channel) {
    return [
        SELECT Id, Name, Message, Channel
        FROM QuickText
        WHERE IsInsertable = true
        AND Channel INCLUDES (:channel) // channel is een enkele String, bv. 'Email'
        ORDER BY Name
    ];
}
}