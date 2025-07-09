trigger ChatterPostEventTrigger on ChatterPostEvent__e (after insert) {
    List<FeedItem> posts = new List<FeedItem>();

    for (ChatterPostEvent__e e : Trigger.New) {
        if (String.isBlank(e.Parent_Id__c) || String.isBlank(e.Message__c)) {
            continue;
        }

        FeedItem f = new FeedItem();
        f.ParentId = e.Parent_Id__c;
        f.Body = e.Message__c;
        f.Type = 'TextPost';
        posts.add(f);
    }

    if (!posts.isEmpty()) {
        insert posts;
    }
}