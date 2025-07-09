trigger CaseTrigger2 on Case (before insert, before update) {
    for (Case c : Trigger.new) {
        Case oldCase = Trigger.isInsert ? null : Trigger.oldMap.get(c.Id);

        Boolean impactEnUrgencyIngevuld = !String.isBlank(c.Impact__c) && !String.isBlank(c.Urgency__c);
        Boolean priorityIngevuld = !String.isBlank(c.Priority);
        Boolean priorityGewijzigd = Trigger.isInsert || (oldCase != null && c.Priority != oldCase.Priority);

        System.debug('>>> [Trigger] START Case Id: ' + c.Id);
        System.debug('>>> Impact: ' + c.Impact__c);
        System.debug('>>> Urgency: ' + c.Urgency__c);
        System.debug('>>> Priority: ' + c.Priority);
        System.debug('>>> priorityGewijzigd: ' + priorityGewijzigd);

        try {
            // === PAD 2 === Priority gewijzigd → forceer Impact/Urgency + herbereken streefdatum
            if (priorityIngevuld && priorityGewijzigd) {
                System.debug('>>> [Trigger] PAD 2: Priority gewijzigd, herleid Impact & Urgency');

                StreefdatumCalculator.PrioriteitMapping mapping = StreefdatumCalculator.vindCombinatieVoorPrioriteit(c.Priority);
                if (mapping != null) {
                    c.Impact__c = mapping.impact;
                    c.Urgency__c = mapping.urgency;

                    System.debug('>>> [Trigger] Mapping gevonden: Impact=' + c.Impact__c + ', Urgency=' + c.Urgency__c);

                    DateTime target = StreefdatumCalculator.berekenStreefdatum(mapping.impact, mapping.urgency, c.CreatedDate);
                    System.debug('>>> [Trigger] Berekende streefdatum (via priority): ' + target);
                    c.Date_Time_target__c = target;
                } else {
                    System.debug('>>> [Trigger] Geen mapping gevonden voor Priority: ' + c.Priority);
                }
            }

            // === PAD 1 === Impact + Urgency zijn ingevuld → bepaal Priority + bereken streefdatum
            else if (impactEnUrgencyIngevuld) {
                System.debug('>>> [Trigger] PAD 1: Berekening op basis van Impact & Urgency');

                String prioriteit = StreefdatumCalculator.bepaalPrioriteit(c.Impact__c, c.Urgency__c);
                System.debug('>>> [Trigger] Berekende Priority: ' + prioriteit);
                c.Priority = prioriteit;

                DateTime target = StreefdatumCalculator.berekenStreefdatum(c.Impact__c, c.Urgency__c, c.CreatedDate);
                System.debug('>>> [Trigger] Berekende streefdatum (via impact/urgency): ' + target);
                c.Date_Time_target__c = target;
            }

        } catch (Exception e) {
            System.debug('>>> [Trigger] FOUT bij berekening: ' + e.getMessage());
            c.Date_Time_target__c = null;
        }

        System.debug('>>> [Trigger] EIND Case Id: ' + c.Id);
    }
}