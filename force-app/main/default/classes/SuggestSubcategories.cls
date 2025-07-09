public with sharing class SuggestSubcategories {
    @InvocableMethod(label='Voorgestelde subcategorieën')
    public static List<Wrapper> suggest(List<InputWrapper> inputs) {
        String subject = inputs[0].subject.toLowerCase();
        List<String> suggesties = new List<String>();

        if(subject.contains('mail')) suggesties.add('Emailprobleem');
        if(subject.contains('update')) suggesties.add('Updateverzoek');
        if(subject.contains('login')) suggesties.add('Toegangsprobleem');

        while(suggesties.size() < 3) {
            suggesties.add('Overig');
        }

        return new List<Wrapper>{ new Wrapper(suggesties) };
    }

    public class InputWrapper {
        @InvocableVariable public String subject;
    }

    public class Wrapper {
        @InvocableVariable public List<String> suggesties;
        public Wrapper(List<String> s) { this.suggesties = s; }
    }
}