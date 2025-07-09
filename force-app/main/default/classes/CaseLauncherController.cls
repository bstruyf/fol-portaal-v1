public without sharing class CaseLauncherController {

@AuraEnabled(cacheable=true)
public static List<String> getOriginValues() {
    List<String> values = new List<String>();
    Schema.DescribeFieldResult fieldResult = Case.Origin.getDescribe();
    for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
        if (entry.isActive()) values.add(entry.getLabel());
    }
    return values;
}

@AuraEnabled(cacheable=true)
public static List<String> getPriorityValues() {
    List<String> values = new List<String>();
    Schema.DescribeFieldResult fieldResult = Case.Priority.getDescribe();
    for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
        if (entry.isActive()) values.add(entry.getLabel());
    }
    return values;
}
@AuraEnabled(cacheable=true)
public static List<String> getStatusValues() {
    List<String> values = new List<String>();
    Schema.DescribeFieldResult fieldResult = Case.Status.getDescribe();
    for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
        if (entry.isActive()) values.add(entry.getLabel());
    }
    return values;
}
@AuraEnabled(cacheable=true)
public static List<String> getBehandelaarsgroepValues() {
    List<String> values = new List<String>();
    Schema.DescribeFieldResult fieldResult = Case.Behandelaarsgroep__c.getDescribe();
    for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
        if (entry.isActive()) values.add(entry.getLabel());
    }
    return values;
}

    @AuraEnabled(cacheable=true)
    public static List<String> getSoortMeldingValues() {
        List<String> values = new List<String>();
        Schema.DescribeFieldResult fieldResult = Case.Soort_Melding__c.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry entry : picklistEntries) {
            if (entry.isActive()) {
                values.add(entry.getLabel());
            }
        }
        return values;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getSoortBinnenkomstValues() {
        List<String> values = new List<String>();
        Schema.DescribeFieldResult fieldResult = Case.Soort_Binnenkomst__c.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry entry : picklistEntries) {
            if (entry.isActive()) {
                values.add(entry.getLabel());
            }
        }
        return values;
    }

    @AuraEnabled(cacheable=true)
    public static List<Case> getRecentCases(Id accountId) {
        if (accountId == null) return new List<Case>();

        Date threeMonthsAgo = Date.today().addMonths(-3);

        return [
            SELECT Id,
                   Record_Type__c,
                   Description,
                   Aanmelder__r.Name,
                   CaseNumber,
                   Owner.Name,
                   Category__c,
                   Subcategory__c,
                   Status,
                   CreatedDate,
                   Date_Time_target__c,
                   Priority,
                   ClosedDate,
                   Subject
            FROM Case
            WHERE AccountId = :accountId
              AND CreatedDate >= :threeMonthsAgo
            ORDER BY CreatedDate DESC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<FeedItem> getCaseFeed(Id caseId) {
        return [
            SELECT Id, Body, CreatedBy.Name, CreatedDate
            FROM FeedItem
            WHERE ParentId = :caseId
            ORDER BY CreatedDate DESC
            LIMIT 20
        ];
    }
@AuraEnabled
public static void logCaseLaunch(Id caseId, Id contactId, String aantekeningen, String soortBinnenkomst) {
    Long startTime = Limits.getCpuTime();

    if (String.isBlank(caseId)) return;

    String contactNaam = '';
    if (contactId != null) {
        Contact c = [SELECT FirstName, LastName FROM Contact WHERE Id = :contactId LIMIT 1];
        contactNaam = c.FirstName + ' ' + c.LastName;
    }

    String body = 'Nieuwe aanmelding via CaseLauncher\n';
    body += 'Contactpersoon: ' + contactNaam + '\n';
    body += 'Soort binnenkomst: ' + soortBinnenkomst + '\n';
    body += 'Aantekeningen:\n' + aantekeningen;

    FeedItem post = new FeedItem();
    post.ParentId = caseId;
    post.Body = body;
    post.Type = 'TextPost';
    insert post;

    Long endTime = Limits.getCpuTime();
    System.debug('⏱ logCaseLaunch duur (ms): ' + (endTime - startTime));
}
@AuraEnabled
    public static void setCaseInProgress(Id caseId) {
        if (caseId == null) {
            throw new AuraHandledException('Geen CaseId meegegeven');
        }
        Case c = [SELECT Id, Status FROM Case WHERE Id = :caseId LIMIT 1];
        c.Status = 'Response Received';
        update c;
    }
@AuraEnabled
    public static void notifyOwnerOnReopen(
        Id caseId,
        String caseNumber,
        String shortDescription,
        Id contactReopenedId
    ) {
        if (caseId == null) {
            throw new AuraHandledException('Geen CaseId meegegeven');
        }
        // 1) Haal de Case op, inclusief OwnerId
        Case c = [
            SELECT Id,
                   CaseNumber,
                   Subject,
                   OwnerId,
				   Behandelaarsgroep__c
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
        
        Id ownerId = c.OwnerId;
        // 2) Controleer of de Owner een User is (niet een Queue/Group)
        if (ownerId.getSObjectType() != User.SObjectType) {
            return;
        }
        
        // 3) Haal de User (eigenaar) op
        User ownerUser = [
            SELECT Id, Name, Email,FirstName
            FROM User
            WHERE Id = :ownerId
              AND IsActive = TRUE
            LIMIT 1
        ];
        
        // 4) Haal de naam van de Contact die heropende op
        Contact reopeningContact = [
            SELECT Id, Name
            FROM Contact
            WHERE Id = :contactReopenedId
            LIMIT 1
        ];
        
        // 5) Bouw de URL naar de Case (gebruik getOrgDomainUrl ipv getSalesforceBaseUrl)
        //    URL.getOrgDomainUrl().toExternalForm() geeft bv. "https://mycompany.my.salesforce.com"
        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        String incidentLink = baseUrl + '/' + c.Id;
        
         // 6) Construeren van de Chatter-berichttekst met @mention op de Case-feed
        //    Volg exact het patroon uit jouw ChatterMentionService, maar vul hier de gewenste tekst in.

        // 6a) Maak de tekstsegmenten voor vóór de mention
        ConnectApi.TextSegmentInput tekstVoor = new ConnectApi.TextSegmentInput();
        tekstVoor.text = 
            'Ha ' + ownerUser.Name + ',' + '\n\n' +
            'Het incident met nummer ' + caseNumber + ' (' + incidentLink + ') – ' +
            shortDescription + ' – dat jij eerder hebt afgesloten, is opnieuw geopend door ' +
            reopeningContact.Name + '. Blijkbaar is het probleem toch nog niet opgelost.' + '\n\n' +
            'Het incident staat inmiddels weer in de queue van jouw team.' + '\n\n';

        // 6b) Maak het MentionSegment (vermeld de eigenaar écht)
        ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
        mentionSegment.id = ownerId;

        // 6c) Tekst na de mention
        ConnectApi.TextSegmentInput tekstNa = new ConnectApi.TextSegmentInput();
        tekstNa.text = 
            'Met vriendelijke groet,' + '\n' +
            'Jouw Serviceteam';

        // 6d) Zet alle segmenten in een lijst
        List<ConnectApi.MessageSegmentInput> segmenten = new List<ConnectApi.MessageSegmentInput>{
            tekstVoor,
            mentionSegment,
            tekstNa
        };

        // 6e) Stel de body in
        ConnectApi.MessageBodyInput bodyInput = new ConnectApi.MessageBodyInput();
        bodyInput.messageSegments = segmenten;

        // 6f) Stel het FeedItemInput in (dit is een FeedElementInput onder hoods)
        ConnectApi.FeedItemInput feedInput = new ConnectApi.FeedItemInput();
        feedInput.body            = bodyInput;
        feedInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
        // Plaats de post op de Case-feed door subjectId = c.Id
        feedInput.subjectId       = ownerId;

        // 6g) Post naar Chatter
        ConnectApi.ChatterFeeds.postFeedElement(
            /* communityId */ null,
            /* input */       (ConnectApi.FeedElementInput) feedInput
        );
        
        // 8) Stel de e-mailtekst samen (HTML)
        String emailBody = 
            '<p>Dag ' + ownerUser.FirstName + ',</p>' +
            '<p>Het incident met nummer <a href="' + incidentLink + '">' + caseNumber + '</a> – ' +
            shortDescription + ' – dat jij eerder hebt afgesloten, ' +
            'is opnieuw geopend door ' + reopeningContact.Name + '.<br/>' +
            'Blijkbaar is het probleem toch nog niet opgelost.</p>' +
            '<p>Het incident staat inmiddels weer in de queue van jouw team.</p>' +
            '<p>Met vriendelijke groet,</p>';
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTargetObjectId(ownerUser.Id);
        mail.setSubject('Incident ' + caseNumber + ' is opnieuw geopend');
        mail.setHtmlBody(emailBody);
        mail.setSaveAsActivity(false);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

        // 9) BEHANDELAAR TERUGWIJZIGEN naar de Queue die in Behandelaarsgroep__c staat
        if (c.Behandelaarsgroep__c != null) {
            // Zoek de Queue (Group) op basis van de naam uit de picklist
            Group grp = [
                SELECT Id
                FROM Group
                WHERE Type = 'Queue'
                  AND Name = :c.Behandelaarsgroep__c
                LIMIT 1
            ];
            if (grp != null) {
                // Zet de OwnerId van de Case naar de Queue-Id
                c.OwnerId = grp.Id;
                update c;
    }
}
    }
@AuraEnabled(cacheable=true)
public static String getContactEmail(Id contactId) {
    if (contactId == null) return null;

    Contact c = [SELECT Email FROM Contact WHERE Id = :contactId LIMIT 1];
    return c.Email;
}
@AuraEnabled
public static void updateContactEmail(Id contactId, String email) {
    if (String.isBlank(email) || contactId == null) {
        throw new AuraHandledException('ContactId en e-mail zijn vereist.');
    }

    Contact c = new Contact(Id = contactId, Email = email);
    update c;
}
@AuraEnabled
public static String getApotheekteamEmail(Id accountId) {
    if (accountId == null) return null;

    List<User> users = [
        SELECT Contact.Email
        FROM User
        WHERE Profile.Name = 'Farmad Portal User'
          AND Contact.LastName = 'Apotheekteam'
          AND Contact.AccountId = :accountId
          AND Contact.Email != null
        LIMIT 1
    ];
    return users.isEmpty() ? null : users[0].Contact.Email;
}
@AuraEnabled
public static Id createNewCase(
    Id accountId,
    Id contactId,
    String subject,
    String description,
    String description2,
    String behandelaarsgroep,
    String priority,
    String soortBinnenkomst,
    String soortMelding,
    String status,
    String category,
    String subcategory
) {
    Long startTime = Limits.getCpuTime(); // Start timer

    if (accountId == null) {
        throw new AuraHandledException('AccountId is verplicht');
    }

    // Zoek extra contact: 'Apotheekteam' + Farmad Portal User
    List<User> matchingUsers = [
        SELECT ContactId
        FROM User
        WHERE Profile.Name = 'Farmad Portal User'
          AND Contact.Name = 'Apotheekteam'
          AND Contact.AccountId = :accountId
          AND ContactId != null
        LIMIT 1
    ];

    Id apotheekteamContactId = matchingUsers.isEmpty() ? null : matchingUsers[0].ContactId;

    Case c = new Case(
    AccountId = accountId,
    Aanmelder__c = contactId,
    Subject = subject,
    Description = description,
    Description2__c = description2,
    Behandelaarsgroep__c = behandelaarsgroep,
    Priority = priority,
    Soort_Binnenkomst__c = soortBinnenkomst,
    Soort_Melding__c = soortMelding,
    Status = status,
    Category__c = category,
    Subcategory__c = subcategory,
    Origin = 'Telefonisch',
    ContactId = apotheekteamContactId,
    OwnerId = UserInfo.getUserId()
);

    insert c;

    Long endTime = Limits.getCpuTime(); // End timer
    System.debug('⏱ createNewCase duur (ms): ' + (endTime - startTime));

    return c.Id;
}
@AuraEnabled(cacheable=true)
public static List<Case> searchSimilarCases(String searchTerm) {
    if (String.isBlank(searchTerm)) return new List<Case>();

    // Beperk tot laatste 12 maanden na ophalen
    Date recentLimit = Date.today().addMonths(-12);

    List<Case> finalResults = new List<Case>();

    // 🔍 SOSL zoekt in Subject, Description en FeedItem.Body tegelijk
    List<List<SObject>> searchResults = [
        FIND :('*' + searchTerm + '*') 
        IN ALL FIELDS 
        RETURNING 
            Case(Id, CaseNumber, Subject, Description2__c, CreatedDate, Category__c, Subcategory__c, Status WHERE CreatedDate = LAST_N_MONTHS:12),
            FeedItem(ParentId WHERE CreatedDate = LAST_N_MONTHS:12)
        LIMIT 20
    ];

    // Stap 1: directe Case-hits
    if (!searchResults.isEmpty()) {
        List<SObject> casesFound = searchResults[0];
        for (SObject s : casesFound) {
            Case c = (Case)s;
            finalResults.add(c);
        }

        // Stap 2: hits via FeedItem → Cases ophalen via ParentId
        if (searchResults.size() > 1 && finalResults.size() < 10) {
            List<SObject> feedMatches = searchResults[1];
            Set<Id> feedParentIds = new Set<Id>();
            for (SObject s : feedMatches) {
                FeedItem f = (FeedItem)s;
                feedParentIds.add(f.ParentId);
            }

            if (!feedParentIds.isEmpty()) {
                List<Case> extraCases = [
                    SELECT Id, CaseNumber, Subject, Description, CreatedDate, Category__c, Subcategory__c, Status
                    FROM Case
                    WHERE Id IN :feedParentIds
                    AND CreatedDate >= :recentLimit
                ];

                for (Case ec : extraCases) {
                    if (!finalResults.contains(ec)) {
                        finalResults.add(ec);
                    }
                }
            }
        }
    }

    return finalResults;
}
@AuraEnabled(cacheable=true)
public static List<EmailMessage> getEmailMessagesForCase(Id caseId) {
    if (caseId == null) return new List<EmailMessage>();

    return [
        SELECT Id, Subject, FromAddress, ToAddress, HtmlBody, CreatedDate
        FROM EmailMessage
        WHERE ParentId = :caseId
        ORDER BY CreatedDate DESC
        LIMIT 10
    ];
}
@AuraEnabled(cacheable=true)
public static List<Knowledge__kav> suggestKnowledgeArticles(String query) {
    if (String.isBlank(query)) return new List<Knowledge__kav>();

    System.debug('📥 Ontvangen input van JS: "' + query + '"');

    List<String> woorden = query.trim().split('\\s+');
    List<String> tokens = new List<String>();

    for (String w : woorden) {
        if (w != null && w.length() >= 3) {
            tokens.add('*' + String.escapeSingleQuotes(w) + '*');
        }
    }

    if (tokens.isEmpty()) return new List<Knowledge__kav>();

    String pattern = String.join(tokens, ' ');
String sosl = 'FIND {' + pattern + '} IN ALL FIELDS RETURNING Knowledge__kav(Id, Title,Environment__c, Cause__c, Question__c, Answer__c WHERE PublishStatus = \'Online\' AND IsLatestVersion = true)';
    System.debug('📘 Gebouwde SOSL-query: ' + sosl);

    List<List<SObject>> result = Search.query(sosl);
    System.debug('📊 Aantal gevonden artikelen: ' + (result.isEmpty() ? 0 : result[0].size()));

    return result.isEmpty() ? new List<Knowledge__kav>() : (List<Knowledge__kav>)result[0];
}
public class CategoryWrapper {
    @AuraEnabled public String category;
    @AuraEnabled public List<String> subcategories;
}

@AuraEnabled(cacheable=true)
public static List<CategoryWrapper> getCategoryAndSubcategoryOptions() {
    Map<String, Set<String>> mapCatToSubs = new Map<String, Set<String>>();

    for (Category__c record : [
        SELECT Category__c, SubCategory__c 
        FROM Category__c 
        WHERE Category__c != null AND SubCategory__c != null
    ]) {
        if (!mapCatToSubs.containsKey(record.Category__c)) {
            mapCatToSubs.put(record.Category__c, new Set<String>());
        }
        mapCatToSubs.get(record.Category__c).add(record.SubCategory__c);
    }

    List<CategoryWrapper> result = new List<CategoryWrapper>();
    for (String cat : mapCatToSubs.keySet()) {
        CategoryWrapper w = new CategoryWrapper();
        w.category = cat;
        w.subcategories = new List<String>(mapCatToSubs.get(cat));
        result.add(w);
    }

    return result;
}
@AuraEnabled
public static Id createContact(String firstName, String lastName, String email, Id accountId) {
    if (String.isBlank(firstName) || String.isBlank(lastName) || String.isBlank(email) || String.isBlank(accountId)) {
        throw new AuraHandledException('Alle velden (voornaam, achternaam, e-mail en accountId) zijn verplicht.');
    }

    Contact c = new Contact();
    c.FirstName = firstName;
    c.LastName = lastName;
    c.Email = email;
    c.AccountId = accountId;

    insert c;

    return c.Id;
}
}