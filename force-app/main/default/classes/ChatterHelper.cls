public with sharing class ChatterHelper {
    
    public class FeedRequest {
        @InvocableVariable(label='Record ID (Parent)')
        public String parentId;

        @InvocableVariable(label='Berichttekst')
        public String message;
    }

    @InvocableMethod(label='Post systeem Chatterbericht')
    public static void postChatterMessage(List<FeedRequest> requests) {
        List<FeedItem> posts = new List<FeedItem>();
        
        for (FeedRequest req : requests) {
            if (String.isBlank(req.parentId) || String.isBlank(req.message)) {
                continue; // sla over als info ontbreekt
            }

            FeedItem post = new FeedItem();
            post.ParentId = req.parentId;
            post.Body = req.message;
            post.Type = 'TextPost';
            posts.add(post);
        }

        if (!posts.isEmpty()) {
            insert posts;
        }
    }
}