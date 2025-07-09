trigger CaseTrigger on Case (before update) {
    // Let op: Trigger.new is List<Case>, Trigger.oldMap is Map<Id,Case>
    CaseOwnerHandler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
}