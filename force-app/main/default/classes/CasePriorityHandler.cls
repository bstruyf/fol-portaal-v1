public without sharing class CasePriorityHandler {
    /**
     * Vul het veld TargetDateTime__c op basis van Priority:
     * - Critical     = CreatedDate + 2 uur
     * - High         = CreatedDate + 24 uur
     * - Medium-High  = CreatedDate + 48 uur
     * - Medium       = CreatedDate + 5 dagen
     */
    public static void setTargetDateTime(List<Case> newCases, Map<Id, Case> oldMap) {
        for (Case c : newCases) {
            // 1) Bepaal of we moeten recalculeren:
            Boolean isInsert = (oldMap == null) || !oldMap.containsKey(c.Id);
            Boolean priorityChanged = isInsert;
            if (!isInsert) {
                Case oldCase = oldMap.get(c.Id);
                if (oldCase != null && c.Priority != oldCase.Priority) {
                    priorityChanged = true;
                }
            }
            if (!priorityChanged) {
                continue;
            }

            // 2) Kies basis‐timestamp
            Datetime basis = c.CreatedDate;
            if (basis == null) {
                basis = System.now();
            }

            // 3) Bereken nieuwe target
            Datetime newTarget;
            if ('Critical_P1'.equals(c.Priority)) {
                newTarget = basis.addHours(2);
            } else if ('High_P2'.equals(c.Priority)) {
                newTarget = basis.addHours(24);
            } else if ('Medium-High_P3'.equals(c.Priority)) {
                newTarget = basis.addHours(48);
            } else if ('Medium_P4'.equals(c.Priority)) {
                newTarget = basis.addDays(5);
            } else {
                // onbekende Priority, skip
                continue;
            }

            // 4) Schrijf in het doelveld (before-trigger pakt dit automatisch op)
            c.Date_Time_target__c = newTarget;
        }
    }
}