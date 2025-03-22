public class HTTPOracleInvoiceUpdateQueueable implements Queueable, Database.AllowsCallouts {


    private OracleProjectInvoice__c OracleInvoiceRecord;
    // Constructor to accept the list of IDs
    public HTTPOracleInvoiceUpdateQueueable(OracleProjectInvoice__c OracleInvoiceRecord) {
        this.OracleInvoiceRecord = OracleInvoiceRecord;
    }
    public void execute(QueueableContext context) {
        List<String> returnList = new List<String>();


        Id recordId;
        String OracleSFRecordId;
        String HTTPrequestEndpont;
        String OracleInvoiceRecordId;
        String TaskIdDisplay;
        String TempParserGetCurrentName ;
        String TempParserGetText;
        String TempParserGetToken;
        Integer Invoice202020=0;
        Integer CreateNewRecords=0;

        //recordId = 'a2HVF000000GRqg2AG';
        OracleSFRecordId = OracleInvoiceRecord.Id;
        OracleInvoiceRecordId = OracleInvoiceRecord.OracleRecordId__c;
        
        if ( OracleSFRecordId == 'a2HVF000000GRnR2AW' ) {
            CreateNewRecords=1;
        }

        OracleProjectInvoice__c invoice = [SELECT Id, OracleRecordId__c, Paid_Amount__c FROM OracleProjectInvoice__c WHERE Id = :OracleSFRecordId];
         //OracleRecordId = invoice.oracleRecordId__c;
    //details 
         
        if(CreateNewRecords == 1) {
            //calling creation oracle query
            HTTPrequestEndpont = '/fscmRestApi/resources/11.13.18.05/invoices/?q=CreationDate%3E2025-01-15T00:01:00.001Z&fields=InvoiceId,InvoiceNumber,CreationDate&limit=200&onlyData=true';
        } else {
            //calling specific oracle invoice 
            HTTPrequestEndpont = '/fscmRestApi/resources/11.13.18.05/invoices/' + OracleInvoiceRecordId +  '?fields=InvoiceId,InvoiceNumber,InvoiceAmount,PaidStatus,Supplier,SupplierNumber,SupplierSite,LegalEntity;invoiceLines:LineNumber,LineAmount,AccountingDate,DistributionCombination,invoiceLineProjectDff:InvoiceId,_TASK_ID_Display,_PROJECT_ID_Display&onlyData=true';
        }


        // Create an HTTP request
        HttpRequest request = new HttpRequest();

        //  request.setEndpoint('callout:OracleCredential'+ HTTPrequestEndpont);
        request.setEndpoint('callout:OracleProductionExternalCredentials'+ HTTPrequestEndpont);
        request.setMethod('GET');
        
        // Send the request and get the response
        Http http = new Http();
        HttpResponse response = http.send(request);
        

        
    
        
        // Check the response status code
        if (response.getStatusCode() == 200) {
            // Parse the response JSON to get the invoice data
            JSONParser parser = JSON.createParser(response.getBody());
            
            
            Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            
            if(CreateNewRecords == 1) {
                // Create a list to store the new OracleProjectInvoice__c records
                List<OracleProjectInvoice__c> oracleProjectInvoices = new List<OracleProjectInvoice__c>();

                List<Object> items = (List<Object>) m.get('items');
                for (Object itemObject : items) {
                    Map<String, Object> item = (Map<String, Object>) itemObject;
                    System.debug(item.get('InvoiceId'));
                // String invoiceId = (String) item.get('InvoiceId');
                String invoiceId = String.valueOf(item.get('InvoiceId')); 
                String invoiceNumber = (String) item.get('InvoiceNumber');
                    String creationDate = (String) item.get('CreationDate');
                    System.debug('InvoiceId: ' + invoiceId + ', InvoiceNumber: ' +  invoiceNumber + ', CreationDate: ' + creationDate);

                    // Create a new OracleProjectInvoice__c record
                    OracleProjectInvoice__c oracleProjectInvoice = new OracleProjectInvoice__c();

                    // Assign the invoiceNumber to invoiceNumber__c and the creationDate to oraclecreationdate__c
                    oracleProjectInvoice.OracleRecordId__c = invoiceId;
                    oracleProjectInvoice.InvoiceNumber__c = invoiceNumber;
                    oracleProjectInvoice.TempMassUpdate__c	= '01162025';
                    //oracleProjectInvoice.oraclecreationdate__c = creationDate;

                    // Add the new record to the list
                    oracleProjectInvoices.add(oracleProjectInvoice);
                }
                insert oracleProjectInvoices;
            } else {
        

                System.debug(response.getBody());
                System.debug(m);
                //Map<String, Object> dim =  (Map<String, Object>)m.get('invoiceLines');
                //String ProjDffProjID = String.valueOf (m.get('_PROJECT_ID_Display'));
                // String ProjDffProjID = (String)dim.get('LineAmount');
                String getSupplierNumber = (String)m.get('SupplierNumber');
            // System.debug('Difff:  ' + ProjDffProjID);
                system.debug('SupplierNo'+ getSupplierNumber);
                System.debug(parser);

                invoice.OracleUpdateAttempted__c = 1;
                

                while (parser.nextToken()!= null) {
                    system.debug('parser LINE{  '+ parser.getText() + '-----' + parser.getCurrentName() + '-----' + parser.getCurrentToken());
                    
                    TempParserGetToken = parser.getCurrentToken().toString();
                    if( TempParserGetToken.left(5)=='VALUE') {
                        TempParserGetCurrentName = parser.getCurrentName() ;
                        switch on (TempParserGetCurrentName) {
                            when 'InvoiceNumber'{
                                invoice.InvoiceNumber__c = parser.getText();
                                continue;}
                            when 'InvoiceAmount'{
                                invoice.Paid_Amount__c = parser.getDecimalValue();
                                continue;}
                            when 'PaidStatus'{
                                invoice.PaidStatus__c = parser.getText();
                                continue;}
                            when 'Supplier'{
                                invoice.OracleSupplier__c = parser.getText();
                                continue;}
                            when 'LegalEntity'{
                                invoice.OracleLegalEntity__c = parser.getText();
                                continue;}
                            when 'SupplierNumber'{
                                invoice.OracleSupplierNumber__c = parser.getText();
                                continue;}
                            when 'LineAmount'{
                                invoice.LineAmount__c = parser.getDecimalValue();
                                continue;}
                            when 'AccountingDate'{
                                invoice.OracleAccountingDate__c = parser.getDateValue();
                                continue;}
                            when 'DistributionCombination'{
                                invoice.DistributionCombination__c = parser.getText();
                                continue;}
                            when 'LineNumber'{
                                invoice.LineNumber__c = parser.getIntegerValue();
                                continue;}
                            when '_PROJECT_ID'{
                                invoice.LineProjectId__c = parser.getText();
                                continue;}
                            when '_PROJECT_ID_Display'{
                                invoice.LineProjectDisplay__c = parser.getText();
                                continue;}
                            when '_TASK_ID'{
                                invoice.LineTaskId__c = parser.getText();
                                continue;}
                            when '_TASK_ID_Display'{
                                invoice.LineTaskIdDisplay__c = parser.getText();
                                TaskIdDisplay = parser.getText();
                                if(TaskIdDisplay=='20-20-20') {
                                    Invoice202020 = 1;
                                    invoice.OracleReportingInvoice__c = 1;
                                    break;
                                }
                                continue;}
                            when else {
                                // Handle unrecognized field here
                                continue;
                            }
                        }
                    }
                
                }
                If (Invoice202020==0) {
                   
                    invoice.Paid_Amount__c = null;                   
                    invoice.PaidStatus__c = '';                    
                    invoice.OracleSupplier__c = '';                    
                    invoice.OracleLegalEntity__c = '';                    
                    invoice.OracleSupplierNumber__c = '';                 
                    invoice.LineAmount__c = null;                 
                    invoice.OracleAccountingDate__c = null;                   
                    invoice.DistributionCombination__c = '';                    
                    invoice.LineNumber__c = null;                  
                    invoice.LineProjectId__c = '';                   
                    invoice.LineProjectDisplay__c = '';                   
                    invoice.LineTaskId__c = '';
                }
                //  invoice.LineTaskIdDisplay__c = parser.getText();
                // invoice.InvoiceNumber__c = '';
                //invoice.Oracle_Description__c ='apex did this';
        
                try {
                    update invoice;
                } catch (Exception e) {
                    System.debug('Error updating invoice{ ' + e.getMessage());
                }

                returnList.add(response.getBody());
            }
        }
    }
    
    @InvocableMethod(label='Oracle Invoice Update' description='Queues a job to get Invoice Data from Oracle.')
    public static void createOracleInvoice(List<OracleProjectInvoice__c> OracleInvoiceRecords) {
        // Loop over the provided records and enqueue each job individually
        for (OracleProjectInvoice__c record : OracleInvoiceRecords) {
            // Create a new Queueable job for each record
            HTTPOracleInvoiceUpdateQueueable job = new HTTPOracleInvoiceUpdateQueueable(record);
            
            // Enqueue the job
            System.enqueueJob(job);
        }
    }
}