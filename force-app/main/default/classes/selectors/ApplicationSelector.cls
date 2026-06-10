public abstract with sharing class ApplicationSelector {

    public abstract Schema.SObjectType getSObjectType();

    public abstract List<Schema.SObjectField> getSObjectFieldList();

    // Verifica que o usuário tem acesso de leitura ao objeto
    protected void assertIsAccessible() {
        if (!getSObjectType().getDescribe().isAccessible()) {
            throw new System.NoAccessException();
        }
    }
}
