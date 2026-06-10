public abstract class TriggerHandler {

    private static Set<String> bypassedHandlers = new Set<String>();

    // Ponto de entrada — chamado diretamente pelo trigger
    public void run() {
        if (isBypassed()) {
            return;
        }

        switch on Trigger.operationType {
            when BEFORE_INSERT  { beforeInsert(); }
            when BEFORE_UPDATE  { beforeUpdate(); }
            when BEFORE_DELETE  { beforeDelete(); }
            when AFTER_INSERT   { afterInsert(); }
            when AFTER_UPDATE   { afterUpdate(); }
            when AFTER_DELETE   { afterDelete(); }
            when AFTER_UNDELETE { afterUndelete(); }
        }
    }

    // Métodos sobrescrevíveis pelos handlers concretos
    protected virtual void beforeInsert()   {}
    protected virtual void beforeUpdate()   {}
    protected virtual void beforeDelete()   {}
    protected virtual void afterInsert()    {}
    protected virtual void afterUpdate()    {}
    protected virtual void afterDelete()    {}
    protected virtual void afterUndelete()  {}

    // Suporte a bypass por nome da classe (útil em testes de integração)
    public static void bypass(String handlerName) {
        bypassedHandlers.add(handlerName);
    }

    public static void clearBypass(String handlerName) {
        bypassedHandlers.remove(handlerName);
    }

    public static void clearAllBypasses() {
        bypassedHandlers.clear();
    }

    public static Boolean isBypassed(String handlerName) {
        return bypassedHandlers.contains(handlerName);
    }

    private Boolean isBypassed() {
        return bypassedHandlers.contains(this.getHandlerName());
    }

    private String getHandlerName() {
        return String.valueOf(this).split(':')[0];
    }
}
