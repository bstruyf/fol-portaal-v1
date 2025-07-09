public without sharing class CaseOwnerHandler {
    public static void onBeforeUpdate(List<Case> newList, Map<Id, Case> oldMap) {
        // Stap 1: Verzamel alle gewijzigde BehandelaarGroep__c waarden
        Set<String> groepNamen = new Set<String>();
        for (Case cNew : newList) {
            Case cOld = oldMap.get(cNew.Id);
            if (cNew.BehandelaarsGroep__c != cOld.BehandelaarsGroep__c &&
                String.isNotBlank(cNew.BehandelaarsGroep__c)) {
                groepNamen.add(cNew.BehandelaarsGroep__c);
            }
        }
        if (groepNamen.isEmpty()) return;

        // Stap 2: Query alle Queues met deze namen
        Map<String, Id> queuesByName = new Map<String, Id>();
        for (Group g : [
            SELECT Id, Name
              FROM Group
             WHERE Type = 'Queue'
               AND Name IN :groepNamen
        ]) {
            queuesByName.put(g.Name, g.Id);
        }

        // Stap 3: Voor elke Case die van groep veranderd is, zet de nieuwe OwnerId
        for (Case cNew : newList) {
            Case cOld = oldMap.get(cNew.Id);
            if (cNew.BehandelaarsGroep__c != cOld.BehandelaarsGroep__c) {
                Id qid = queuesByName.get(cNew.BehandelaarsGroep__c);
                if (qid != null) {
                    cNew.OwnerId = qid;
                }
            }
        }
        // GEEN extra DML nodig, want we're in before update en hebben OwnerId rechtstreeks gezet
    }
}