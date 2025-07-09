public with sharing class CaseEmailFlowService {

    public class EmailInput {
        @InvocableVariable(label='Case ID') public Id caseId;
        @InvocableVariable(label='Emailtemplate ID') public Id templateId;
        @InvocableVariable(label='Log naar Case-feed') public Boolean logToFeed;
    }

    @InvocableMethod(label='Verstuur e-mail via e-mailtemplate')
    public static void sendTemplateEmail(List<EmailInput> inputs) {
        for (EmailInput input : inputs) {
            if (input.caseId == null || input.templateId == null) continue;

            // 📥 Haal Case + Contact info op
            Case c = [
                SELECT Id, Subject, ContactId, Contact.Email,
                       MailToAanmelder__c, Aanmelder__c, Aanmelder__r.Email
                FROM Case
                WHERE Id = :input.caseId
                LIMIT 1
            ];

            // 📬 Ontvanger bepalen (voorkeur aan Contact, dan Aanmelder)
            // 📬 Verzamelen van geldige e-mailadressen
List<String> recipients = new List<String>();
Id mergeTargetContactId; // Voor TargetObjectId (merge context)

// Contact
if (c.ContactId != null && String.isNotBlank(c.Contact.Email)) {
    recipients.add(c.Contact.Email);
    mergeTargetContactId = c.ContactId;
}

// Aanmelder
if (c.MailToAanmelder__c && c.Aanmelder__c != null && String.isNotBlank(c.Aanmelder__r.Email)) {
    recipients.add(c.Aanmelder__r.Email);
    if (mergeTargetContactId == null) {
        mergeTargetContactId = c.Aanmelder__c;
    }
}

if (recipients.isEmpty() || mergeTargetContactId == null) {
    System.debug('⚠️ Geen geldige e-mailontvangers gevonden voor Case: ' + c.Id);
    continue;
}

            // ✉️ E-mail opstellen
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
mail.setToAddresses(recipients);            
mail.setTargetObjectId(mergeTargetContactId);
            mail.setTemplateId(input.templateId);
            mail.setWhatId(c.Id);
            mail.setSaveAsActivity(true);

            // 📤 Verstuur e-mail
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

            // 📝 FeedItem toevoegen indien aangevinkt
            if (input.logToFeed) {
                FeedItem post = new FeedItem();
                post.ParentId = c.Id;
                post.Body = '📧 E-mail verzonden via template `' + input.templateId + '` naar contactId `' + MergeTargetContactId + '`.';
                post.Type = 'TextPost';
                insert post;
            }
        }
    }
}