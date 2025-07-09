public with sharing class ConvertUTCToBelgiumTime {

    public class Input {
        @InvocableVariable(required=true)
        public Datetime utcDateTime;
    }

    public class Output {
        @InvocableVariable
        public String localDateTimeFormatted;
    }

    @InvocableMethod(label='Convert UTC to Belgium Time Text')
    public static List<Output> convert(List<Input> inputs) {
        List<Output> results = new List<Output>();

        for (Input input : inputs) {
            Output out = new Output();

            System.debug('🧪 INPUT UTC: ' + input.utcDateTime);

            if (input.utcDateTime != null) {
                String formatted = input.utcDateTime.format('dd/MM/yyyy \'om\' HH:mm \'u.\'', 'Europe/Brussels');
                out.localDateTimeFormatted = formatted;

                System.debug('🧪 FINAL OUTPUT: ' + out.localDateTimeFormatted);
            }

            results.add(out);
        }

        return results;
    }
}