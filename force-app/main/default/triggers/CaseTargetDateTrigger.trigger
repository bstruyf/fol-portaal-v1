trigger CaseTargetDateTrigger on Case (before insert, before update) {
    // Trigger.new  = List<Case>, Trigger.oldMap = Map<Id,Case> (null bij insert)
    CasePriorityHandler.setTargetDateTime(Trigger.new, Trigger.oldMap);
}