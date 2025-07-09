trigger NotifyOnChatterPost on FeedItem (after insert) {
    System.debug('▶▶▶ Enter NotifyOnChatterPost trigger, count=' + Trigger.New.size());

    // 1. Verzamel rich-text Chatter-posts op Cases
    List<FeedItem> posts  = new List<FeedItem>();
    Set<Id>       caseIds = new Set<Id>();
    for (FeedItem fi : Trigger.New) {
        if (fi.ParentId.getSObjectType() == Case.SObjectType
         && fi.Type          == 'TextPost'
         && fi.IsRichText) {
            posts.add(fi);
            caseIds.add(fi.ParentId);
        }
    }
    System.debug('Found rich-text FeedItems: ' + posts.size());
    if (posts.isEmpty()) return;

    // 2. Haal Cases met e-mailadressen
    Map<Id, Case> caseMap = new Map<Id, Case>([
        SELECT Id, CaseNumber, Contact.Email
        FROM Case
        WHERE Id IN :caseIds
          AND Contact.Email != null
    ]);
    System.debug('Retrieved Cases with email: ' + caseMap.keySet());
    if (caseMap.isEmpty()) return;

    // 3. Patterns voor sfdc:// en data-URI’s
    Pattern sfdcPattern    = Pattern.compile('sfdc://([0-9A-Za-z]{15,18})');
    Pattern dataUriPattern = Pattern.compile('data:image\\/([^;]+);base64,([^\"\\s]+)');

    List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

    // 4. Voor elke FeedItem: bouw mail
    for (FeedItem fi : posts) {
        System.debug('--- Processing FeedItem Id=' + fi.Id);
        Case c = caseMap.get(fi.ParentId);
        if (c == null) {
            System.debug('⚠️ No Case/email found for FeedItem ' + fi.Id);
            continue;
        }

        // 4a. HTML-body start
        String htmlBody = '<h2>Update op uw case ' + c.CaseNumber + '</h2>' + fi.Body;
        System.debug('Initial htmlBody length: ' + htmlBody.length());

        List<Messaging.EmailFileAttachment> fileAtts = new List<Messaging.EmailFileAttachment>();

        // 4b. Verwerk sfdc:// afbeeldingen
        Matcher m1 = sfdcPattern.matcher(htmlBody);
        Set<Id> docIds = new Set<Id>();
        while (m1.find()) {
            docIds.add((Id)m1.group(1));
        }
        System.debug('Found sfdc documentIds: ' + docIds);

        if (!docIds.isEmpty()) {
            List<ContentVersion> cvs = [
                SELECT ContentDocumentId, VersionData, Title
                FROM ContentVersion
                WHERE ContentDocumentId IN :docIds
                  AND IsLatest = true
            ];
            Map<Id, ContentVersion> cvMap = new Map<Id, ContentVersion>();
            for (ContentVersion cv : cvs) {
                cvMap.put(cv.ContentDocumentId, cv);
            }

            for (Id docId : docIds) {
                ContentVersion cv = cvMap.get(docId);
                if (cv == null) {
                    System.debug('⚠️ No ContentVersion for docId ' + docId);
                    continue;
                }
                String ext = cv.Title.contains('.') 
                    ? cv.Title.substringAfterLast('.') 
                    : 'bin';
                String cid = 'img' + docId + '.' + ext;

                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                efa.setBody(cv.VersionData);
                efa.setFileName(cid);
                efa.setContentType('image/' + ext);
                efa.setInline(true);
                fileAtts.add(efa);
                System.debug('Added inline attachment: ' + cid);

                htmlBody = htmlBody.replace('sfdc://' + docId, 'cid:' + cid);
            }
        }

        // 4c. Verwerk geplakte afbeeldingen (data-URI)
        Matcher m2 = dataUriPattern.matcher(htmlBody);
        while (m2.find()) {
            String ext        = m2.group(1);
            String b64        = m2.group(2);
            Blob   imageBlob  = EncodingUtil.base64Decode(b64);
            String cid        = 'img' + Math.abs(imageBlob.hashCode()) + '.' + ext;

            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setBody(imageBlob);
            efa.setFileName(cid);
            efa.setContentType('image/' + ext);
            efa.setInline(true);
            fileAtts.add(efa);
            System.debug('Added inline data-URI attachment: ' + cid);

            htmlBody = htmlBody.replace(m2.group(0), 'cid:' + cid);
        }

        // 4d. Stel de e-mail samen
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[]{ c.Contact.Email });
        mail.setSubject('Update op uw case ' + c.CaseNumber);
        mail.setHtmlBody(htmlBody);
        mail.setSaveAsActivity(false);
        if (!fileAtts.isEmpty()) {
            mail.setFileAttachments(fileAtts);
            System.debug('Attaching ' + fileAtts.size() + ' inline image(s).');
        }
        mails.add(mail);
        System.debug('Prepared email for Case ' + c.Id);
    }

    // 5. Verstuur batch
    if (!mails.isEmpty()) {
        Messaging.sendEmail(mails);
        System.debug('✅ Sent ' + mails.size() + ' email(s).');
    } else {
        System.debug('No emails to send.');
    }
    System.debug('◀◀◀ Exit NotifyOnChatterPost trigger');
}