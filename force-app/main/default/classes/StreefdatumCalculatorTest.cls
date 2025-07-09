@isTest
public class StreefdatumCalculatorTest {

    @isTest
    static void testBerekenStreefdatum_ValidValues() {
        DateTime start = System.now();
        try {
            DateTime result = StreefdatumCalculator.berekenStreefdatum(
                '1 pharmacy completely',
                'Down (not operational)',
                start
            );
            System.debug('>>> RESULT: ' + result);
            System.assert(result > start, 'Streefdatum moet na startdatum liggen');
        } catch (Exception e) {
            System.debug('>>> FOUT: ' + e.getMessage());
            System.assert(false, 'Fout tijdens test: ' + e.getMessage());
        }
    }

    @isTest
    static void testBerekenStreefdatum_InvalidCombo() {
        try {
            StreefdatumCalculator.berekenStreefdatum('Onbekend', 'Willekeurig', System.now());
            System.assert(false, 'Verwacht foutmelding bij ongeldige input');
        } catch (Exception e) {
            System.debug('>>> Exception message: ' + e.getMessage());
            System.assert(e.getMessage() != null, 'Foutmelding moet aanwezig zijn');
        }
    }

    @isTest
    static void testCaseTrigger_ValidInput() {
        Case c = new Case(
            Subject = 'Trigger test',
            Impact__c = '1 pharmacy partly',
            Urgency__c = 'Partly operational'
        );
        insert c;

        Case result = [SELECT Date_Time_target__c FROM Case WHERE Id = :c.Id];
        System.debug('>>> Date_Time_target__c: ' + result.Date_Time_target__c);
        System.assertNotEquals(null, result.Date_Time_target__c, 'Streefdatum moet ingevuld zijn');
    }

    @isTest
    static void testCaseTrigger_SkipWhenNoImpactOrUrgency() {
        Case c = new Case(
            Subject = 'Case zonder impact en urgentie',
            Impact__c = null,
            Urgency__c = null
        );
        insert c;

        Case result = [SELECT Date_Time_target__c FROM Case WHERE Id = :c.Id];
        System.debug('>>> EXPECTED EMPTY Date_Time_target__c: ' + result.Date_Time_target__c);
        System.assertEquals(null, result.Date_Time_target__c, 'Streefdatum moet leeg zijn wanneer Impact en Urgency niet zijn ingevuld');
    }
}