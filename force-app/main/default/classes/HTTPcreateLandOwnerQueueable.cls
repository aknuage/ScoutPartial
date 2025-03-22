public class HTTPcreateLandOwnerQueueable implements Queueable, Database.AllowsCallouts {
    
    private Land_Owner_Payment__c LOPrecord;

    // Constructor to accept the list of IDs
    public HTTPcreateLandOwnerQueueable(Land_Owner_Payment__c LOPrecord) {
        this.LOPrecord = LOPrecord;
    }

    // The execute method runs asynchronously when the job is enqueued
    public void execute(QueueableContext context) {
        List<String> returnList = new List<String>();

        /*
        if(LOPrecord.Vendor_ID__c == null){
            System.debug('No Vendor Id entered on record: ');
            LOPrecord.OracleIntegrationInfo__c = 'No Vendor Id/Supplier Number for this recipient.'  + Datetime.now();
            LOPrecord.Block_Integration_due_to_Error__c = True;
            try {
                update LOPrecord;  // Commit the changes after the callout response
            } catch (DmlException e) {
                System.debug('Error updating LOPrecord after callout failure: ' + e.getMessage());
            }
            //return returnList;
        }
        */

        // Now proceed with the HTTP callout after DML commit
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:OracleCredential' + '/fscmRestApi/resources/11.13.18.05/invoices');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/vnd.oracle.adf.resourceitem+json');

        // Construct the JSON body for the request
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeStringField('BusinessUnit', LOPrecord.OracleBusinessUnit__c ?? '');
        gen.writeStringField('InvoiceSource', LOPrecord.OracleInvoiceSource__c ?? '');
        gen.writeStringField('InvoiceNumber', LOPrecord.InvoiceNumber__c ?? '');
        gen.writeStringField('InvoiceCurrency', LOPrecord.OracleCurrency__c ?? '');
        gen.writeNumberField('InvoiceAmount', LOPrecord.Actual_Payment_to_Payee__c ?? 0);
        gen.writeStringField('InvoiceDate', LOPrecord.OracleDate__c ?? '');
        gen.writeStringField('Supplier', LOPrecord.OracleSupplier__c ?? '');
        gen.writeStringField('SupplierSite', LOPrecord.OracleSupplierSite__c ?? '');
        gen.writeStringField('LegalEntity', LOPrecord.OracleLegalEntity__c ?? '');
        gen.writeStringField('PaymentCurrency', LOPrecord.OracleCurrency__c ?? '');
        gen.writeStringField('InvoiceType', LOPrecord.OracleInvoiceType__c ?? '');
        gen.writeStringField('Description', LOPrecord.NotestoAccounting__c ?? '');
        gen.writeFieldName('invoiceLines');
        gen.writeStartArray();
        gen.writeStartObject();
        gen.writeNumberField('LineNumber', 1);
        gen.writeStringField('LineType', 'Item');
        gen.writeNumberField('LineAmount',LOPrecord.Actual_Payment_to_Payee__c??0);
        gen.writeStringField('DistributionCombination',LOPrecord.OracleDistributionCombination__c??'');
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
        System.debug(jsonText);
        request.setBody(jsonText);

        // Send the HTTP request
        HttpResponse response = http.send(request);

        try{
        // Handle the response based on status code
        if (response.getStatusCode() != 201) {
            System.debug('The status code returned was not expected: ' + response.getStatusCode());
            System.debug('Response Body: ' + response.getBody());
            LOPrecord.OracleIntegrationInfo__c = response.getBody() + ' ' + Datetime.now();
            LOPrecord.Block_Integration_due_to_Error__c = True;
            try {
                update LOPrecord;  // Commit the changes after the callout response
            } catch (DmlException e) {
                System.debug('Error updating LOPrecord after callout failure: ' + e.getMessage());
            }
        } else {
            System.debug(response.getBody());
            Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            String InvoiceID = String.valueOf(m.get('InvoiceId'));
            LOPrecord.OracleIntegrationInfo__c = 'Successful Oracle Creation' + ' ' + Datetime.now();
            LOPrecord.OracleRecordId__c = InvoiceID;
            LOPrecord.Status__c = 'Pending';
            LOPrecord.Paid_Amount__c = LOPrecord.Actual_Payment_to_Payee__c ?? 0;
            LOPrecord.Block_Integration_due_to_Error__c = False;
            try {
                update LOPrecord;  // Commit the changes after the callout success
            } catch (DmlException e) {
                System.debug('Error updating LOPrecord after callout success: ' + e.getMessage());
            }
        }
    } catch (System.CalloutException e) {
        System.debug('Callout Exception: ' + e.getMessage());
        LOPrecord.Block_Integration_due_to_Error__c = True;
        LOPrecord.OracleIntegrationInfo__c = e.getMessage() + ' ' + Datetime.now();
    }

        returnList.add(response.getBody());
    
    }

    @InvocableMethod(label='Create Land Owner Invoice' description='Queues a job to create a land owner invoice in Oracle.')
    public static void createLandOwnerInvoice(List<Land_Owner_Payment__c> LOPrecords) {
        // Loop over the provided records and enqueue each job individually
        for (Land_Owner_Payment__c record : LOPrecords) {
            // Create a new Queueable job for each record
            HTTPcreateLandOwnerQueueable job = new HTTPcreateLandOwnerQueueable(record);
            
            // Enqueue the job
            System.enqueueJob(job);
        }
    }
    
}