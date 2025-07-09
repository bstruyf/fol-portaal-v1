@isTest
public class ConvertUTCToBelgiumTimeTest {

    @isTest
    static void testConversion() {
        Datetime testDatetimeUTC = Datetime.newInstanceGMT(2025, 5, 22, 10, 0, 0);
        System.debug('🧪 Testinput UTC = ' + testDatetimeUTC);

        ConvertUTCToBelgiumTime.Input input = new ConvertUTCToBelgiumTime.Input();
        input.utcDateTime = testDatetimeUTC;

        List<ConvertUTCToBelgiumTime.Input> inputs = new List<ConvertUTCToBelgiumTime.Input>{ input };
        List<ConvertUTCToBelgiumTime.Output> outputs = ConvertUTCToBelgiumTime.convert(inputs);

        System.assertEquals(1, outputs.size());

        System.debug('🧪 TESTOUTPUT = ' + outputs[0].localDateTimeFormatted);
        System.assertEquals('22/05/2025 om 12:00 u.', outputs[0].localDateTimeFormatted);
    }
}