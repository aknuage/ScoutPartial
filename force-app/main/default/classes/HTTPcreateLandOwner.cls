public with sharing class HTTPcreateLandOwner {
    @InvocableMethod
    public static List<String> HTTPcreateLandOwner(List<ID> ids) {
        List<String> returnList = new List<String>();

        Http http = new Http();
        HttpRequest request = new HttpRequest();
       //request.setEndpoint('https://iauuqy-test.fa.ocs.oraclecloud.com/fscmRestApi/resources/11.13.18.05/invoices');
       request.setEndpoint('callout:OracleCredential'+ '/fscmRestApi/resources/11.13.18.05/invoices');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/vnd.oracle.adf.resourceitem+json');
        
        Land_Owner_Payment__c  LOPrecord = [SELECT OracleBusinessUnit__c,OracleInvoiceSource__c, OracleInvoiceGroup__c,InvoiceNumber__c,
        OracleCurrency__c, Actual_Payment_to_Payee__c, OracleDate__c, OracleSupplier__c, OracleSupplierSite__c,	OracleLegalEntity__c, OracleInvoiceType__c, 
        NotestoAccounting__c, OracleDistributionSet__c, OracleProjectId__c, OracleTaskId__c,  OracleExpenditureTypeID__c, OracleOrganizationIdDisplay__c FROM Land_Owner_Payment__c WHERE ID=:ids limit 1];

        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeStringField('BusinessUnit', LOPrecord.OracleBusinessUnit__c??'');
        gen.writeStringField('InvoiceSource', LOPrecord.OracleInvoiceSource__c??'');
        gen.writeStringField('InvoiceNumber', LOPrecord.InvoiceNumber__c??'');
        gen.writeStringField('InvoiceCurrency', LOPrecord.OracleCurrency__c??'');
        gen.writeNumberField('InvoiceAmount', LOPrecord.Actual_Payment_to_Payee__c??0);
        gen.writeStringField('InvoiceDate', LOPrecord.OracleDate__c??'');
        gen.writeStringField('Supplier', LOPrecord.OracleSupplier__c??'');
        gen.writeStringField('SupplierSite',LOPrecord.OracleSupplierSite__c??'');
        gen.writeStringField('LegalEntity', LOPrecord.OracleLegalEntity__c??'');
        gen.writeStringField('PaymentCurrency',  LOPrecord.OracleCurrency__c??'');
        gen.writeStringField('InvoiceType', LOPrecord.OracleInvoiceType__c??'');
        gen.writeStringField('Description', LOPrecord.NotestoAccounting__c ?? '');
        gen.writeFieldName('invoiceLines');
        gen.writeStartArray();
        gen.writeStartObject();
        gen.writeNumberField('LineNumber', 1);
        gen.writeStringField('LineType', 'Item');
        gen.writeNumberField('LineAmount',LOPrecord.Actual_Payment_to_Payee__c??1.17);
        gen.writeFieldName('invoiceLineProjectDff');
        gen.writeStartArray();
        gen.writeStartObject();
        gen.writeStringField('_PROJECT_ID_Display', LOPrecord.OracleProjectId__c??'');
        gen.writeStringField('_TASK_ID_Display', LOPrecord.OracleTaskId__c??'');
        gen.writeStringField('_EXPENDITURE_ITEM_DATE', LOPrecord.OracleDate__c??'');
        gen.writeStringField('_EXPENDITURE_TYPE_ID_Display', 	LOPrecord.OracleExpenditureTypeID__c??'');
        gen.writeStringField('_ORGANIZATION_ID_Display', 	LOPrecord.OracleOrganizationIdDisplay__c??'');
        gen.writeEndObject();
        gen.writeEndArray();
        gen.writeEndObject();
        gen.writeEndArray();
        gen.writeEndObject();
        String jsonText = gen.getAsString();
        
        System.debug('JSON: ' + jsonText);
        
        // Set the body as a JSON object
        request.setBody(jsonText);
        
        System.debug('request payload: ' + request);
        
        HttpResponse response = http.send(request);
        // Parse the JSON response
        
        if(response.getStatusCode() != 201) {
            System.debug('The status code returned was not expected: ' + response.getStatusCode() + ' ' + response.getStatus());
               System.debug('body: ' + response.getBody());
               LOPrecord.OracleIntegrationInfo__c =response.getBody() + ' ' + Datetime.now();
               update LOPrecord;
        } else {
            System.debug(response.getBody());
            Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        
            String InvoiceNumber = (String)m.get('InvoiceNumber');
            String InvoiceID = String.valueOf (m.get('InvoiceId'));
            System.debug('debugging String m:  ' + InvoiceNumber + ' - ' + InvoiceID);

            LOPrecord.OracleIntegrationInfo__c = 'Successful Oracle Creation' + ' ' + Datetime.now();
            LOPrecord.OracleRecordId__c = InvoiceID;
            LOPrecord.Status__c = 'Pending';
            update LOPrecord;
        }           

        returnlist.add(response.getBody());
        return(returnList);
    }
}