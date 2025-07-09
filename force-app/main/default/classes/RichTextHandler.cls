public with sharing class RichTextHandler {
    @InvocableMethod(label='Handle Rich Text' description='Processes rich text input')
    public static List<String> handleRichText(List<Request> input) {
        List<String> results = new List<String>();

        for (Request req : input) {
            // Hier kun je extra verwerking doen als je wilt
            results.add(req.richText);
        }

        return results;
    }

    public class Request {
        @InvocableVariable(label='Rich Text' description='The rich text input')
        public String richText;
    }
}