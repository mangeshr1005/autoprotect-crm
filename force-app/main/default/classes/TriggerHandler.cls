public virtual class TriggerHandler {
    private static Set<String> bypassedHandlers = new Set<String>();
    private static Map<String, Integer> loopCountMap = new Map<String, Integer>();
    private static final Integer MAX_LOOPS = 3;

    public void run() {
        String handlerName = String.valueOf(this).substring(0, String.valueOf(this).indexOf(':'));
        if (bypassedHandlers.contains(handlerName)) return;

        Integer count = loopCountMap.containsKey(handlerName) ? loopCountMap.get(handlerName) + 1 : 1;
        if (count > MAX_LOOPS) return;
        loopCountMap.put(handlerName, count);

        if (Trigger.isBefore) {
            if (Trigger.isInsert) beforeInsert();
            else if (Trigger.isUpdate) beforeUpdate();
            else if (Trigger.isDelete) beforeDelete();
        } else if (Trigger.isAfter) {
            if (Trigger.isInsert) afterInsert();
            else if (Trigger.isUpdate) afterUpdate();
            else if (Trigger.isDelete) afterDelete();
            else if (Trigger.isUndelete) afterUndelete();
        }
    }

    public static void bypass(String handlerName) { bypassedHandlers.add(handlerName); }
    public static void clearBypass(String handlerName) { bypassedHandlers.remove(handlerName); }

    protected virtual void beforeInsert() {}
    protected virtual void beforeUpdate() {}
    protected virtual void beforeDelete() {}
    protected virtual void afterInsert() {}
    protected virtual void afterUpdate() {}
    protected virtual void afterDelete() {}
    protected virtual void afterUndelete() {}
}
