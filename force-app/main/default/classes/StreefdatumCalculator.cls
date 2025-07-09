public class StreefdatumCalculator {

 public class PrioriteitMapping {
        public String impact;
        public String urgency;
        public Integer werkUren;
    }    

public static DateTime berekenStreefdatum(String impact, String urgency, DateTime startDatum) {
        System.debug('>>> Impact: ' + impact);
        System.debug('>>> Urgency: ' + urgency);
        System.debug('>>> Startdatum (UTC): ' + startDatum);
        System.debug('>>> Startdatum (lokale tijd): ' + startDatum.format());

        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = TRUE LIMIT 1];
        Integer werkUren = bepaalWerkuren(impact, urgency);

        if (werkUren == null) {
            throw new AuraHandledException('Ongeldige combinatie van Impact/Urgency: ' + impact + ' / ' + urgency);
        }

        // Bepaal het correcte startmoment
        DateTime werkStart;
        if (BusinessHours.isWithin(bh.Id, startDatum)) {
            werkStart = startDatum;
            System.debug('>>> Binnen openingsuren, start direct vanaf: ' + werkStart.format());
        } else {
            DateTime nextStart = BusinessHours.nextStartDate(bh.Id, startDatum);
            // Forceren naar exact 09:00 lokale tijd (zoals openingsuren aangeven)
            Date onlyDate = nextStart.date();
            werkStart = DateTime.newInstance(onlyDate, Time.newInstance(9, 0, 0, 0));
            System.debug('>>> Buiten openingsuren, geforceerde start op: ' + werkStart.format());
        }

        Long millis = werkUren * 60L * 60L * 1000L;

        DateTime resultaat = BusinessHours.add(bh.Id, werkStart, millis);

        System.debug('>>> Werkuren: ' + werkUren);
        System.debug('>>> Berekend resultaat (UTC): ' + resultaat);
        System.debug('>>> Berekend resultaat (lokale tijd): ' + resultaat.format());

        return resultaat;
    }

    private static Integer bepaalWerkuren(String impact, String urgency) {
        Map<String, Map<String, Integer>> matrix = new Map<String, Map<String, Integer>>{
            '1 patient' => new Map<String, Integer>{
                'Still operational' => 112,
                'Partly operational' => 56,
                'Down (not operational)' => 24
            },
            '1 module' => new Map<String, Integer>{
                'Still operational' => 56,
                'Partly operational' => 24,
                'Down (not operational)' => 16
            },
            '1 pharmacy partly' => new Map<String, Integer>{
                'Still operational' => 24,
                'Partly operational' => 16,
                'Down (not operational)' => 8
            },
            '1 pharmacy completely' => new Map<String, Integer>{
                'Still operational' => 16,
                'Partly operational' => 8,
                'Down (not operational)' => 2
            }
        };

        if (!matrix.containsKey(impact)) return null;
        Map<String, Integer> urgentieMap = matrix.get(impact);
        return urgentieMap.containsKey(urgency) ? urgentieMap.get(urgency) : null;
    }
public static String bepaalPrioriteit(String impact, String urgency) {
    Map<String, Map<String, String>> matrix = new Map<String, Map<String, String>>{
        '1 patiënt' => new Map<String, String>{
            'Still operational' => 'P6 (Low)',
            'Partly operational' => 'P5 (Medium-Low)',
            'Down (not operational)' => 'P4 (Medium)'
        },
        '1 module' => new Map<String, String>{
            'Still operational' => 'P5 (Medium-Low)',
            'Partly operational' => 'P4 (Medium)',
            'Down (not operational)' => 'P3 (Medium-High)'
        },
        '1 pharmacy partly' => new Map<String, String>{
            'Still operational' => 'P4 (Medium)',
            'Partly operational' => 'P3 (Medium-High)',
            'Down (not operational)' => 'P2 (High)'
        },
        '1 pharmacy completely' => new Map<String, String>{
            'Still operational' => 'P3 (Medium-High)',
            'Partly operational' => 'P2 (High)',
            'Down (not operational)' => 'P1 (Critical)'
        }
    };

    if (!matrix.containsKey(impact)) return null;
    Map<String, String> urgentieMap = matrix.get(impact);
    return urgentieMap.containsKey(urgency) ? urgentieMap.get(urgency) : null;
}
public static PrioriteitMapping vindCombinatieVoorPrioriteit(String priority) {
    Map<String, PrioriteitMapping> mapping = new Map<String, PrioriteitMapping>();

    // P1 (Critical)
    PrioriteitMapping p1 = new PrioriteitMapping();
    p1.impact = '1 pharmacy completely';
    p1.urgency = 'Down (not operational)';
    p1.werkUren = 2;
    mapping.put('Critical_P1', p1);

    // P2 (High)
    PrioriteitMapping p2 = new PrioriteitMapping();
    p2.impact = '1 pharmacy partly';
    p2.urgency = 'Down (not operational)';
    p2.werkUren = 8;
    mapping.put('High_P2', p2);

    // P3 (Medium-High)
    PrioriteitMapping p3 = new PrioriteitMapping();
    p3.impact = '1 module';
    p3.urgency = 'Down (not operational)';
    p3.werkUren = 16;
    mapping.put('Medium-High_P3', p3);

    // P4 (Medium)
    PrioriteitMapping p4 = new PrioriteitMapping();
    p4.impact = '1 patient';
    p4.urgency = 'Down (not operational)';
    p4.werkUren = 24;
    mapping.put('Medium_P4', p4);

    // P5 (Medium-Low)
    PrioriteitMapping p5 = new PrioriteitMapping();
    p5.impact = '1 patient';
    p5.urgency = 'Partly operational';
    p5.werkUren = 56;
    mapping.put('Medium-Low_P5', p5);

    // P6 (Low)
    PrioriteitMapping p6 = new PrioriteitMapping();
    p6.impact = '1 patient';
    p6.urgency = 'Still operational';
    p6.werkUren = 112;
    mapping.put('Low_P6', p6);

    return mapping.containsKey(priority) ? mapping.get(priority) : null;
}

}