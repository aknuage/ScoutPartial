public class CreateLandOwnerInvocable {
@InvocableMethod
    public static void GetLopAndMakeCallout(List<ID> ids) {
        Land_Owner_Payment__c  LOPrecord = [SELECT OracleBusinessUnit__c,OracleInvoiceSource__c, OracleInvoiceGroup__c,InvoiceNumber__c,
        OracleCurrency__c, Actual_Payment_to_Payee__c, OracleDate__c, OracleSupplier__c,
        OracleSupplierSite__c,	OracleLegalEntity__c, OracleInvoiceType__c, 
        NotestoAccounting__c, OracleDistributionSet__c, OracleDistributionCombination__c, OracleProjectId__c, 
        OracleTaskId__c,  OracleExpenditureTypeID__c, 
        OracleOrganizationIdDisplay__c FROM Land_Owner_Payment__c WHERE ID=:ids limit 1];
		// Now, pass LOP to Queueable class, which will then perform the callout
        System.enqueueJob(new HTTPcreateLandOwnerQueueable(LOPrecord));
    }
}