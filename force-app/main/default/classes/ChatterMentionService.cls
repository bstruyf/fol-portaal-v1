public class ChatterMentionService {
    public static void postMention(Id gebruikerIdOmTeMentionen, Id recordId, String bericht) {
        // Maak de tekstsegmenten aan
        ConnectApi.TextSegmentInput tekstVoor = new ConnectApi.TextSegmentInput();
        tekstVoor.text = 'Hallo ';

        ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
        mentionSegment.id = gebruikerIdOmTeMentionen;

        ConnectApi.TextSegmentInput tekstNa = new ConnectApi.TextSegmentInput();
        tekstNa.text = ', kun je dit bekijken?';

        // Combineer de segmenten
        List<ConnectApi.MessageSegmentInput> segmenten = new List<ConnectApi.MessageSegmentInput>{
            tekstVoor,
            mentionSegment,
            tekstNa
        };

        // Stel de body van het bericht in
        ConnectApi.MessageBodyInput body = new ConnectApi.MessageBodyInput();
        body.messageSegments = segmenten;

        // Stel het feed item in
        ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
        input.body = body;
        input.feedElementType = ConnectApi.FeedElementType.FeedItem;
        input.subjectId = recordId;

        // Post naar Chatter
        ConnectApi.ChatterFeeds.postFeedElement(null, input);
    }
}