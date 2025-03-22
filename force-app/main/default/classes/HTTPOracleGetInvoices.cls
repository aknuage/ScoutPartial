public with sharing class HTTPOracleGetInvoices {
    public static void makeInvoiceCallout() {

        Id recordId;
        String OracleRecordId;
        String HTTPrequestEndpont;

        recordId = 'a2HVF000000GRqg2AG';
        OracleProjectInvoice__c invoice = [SELECT Id, OracleRecordId__c, Paid_Amount__c FROM OracleProjectInvoice__c WHERE Id = :recordId];
        OracleRecordId = invoice.oracleRecordId__c;
       //details 
         HTTPrequestEndpont = '/fscmRestApi/resources/11.13.18.05/invoices/' + OracleRecordId +  '?fields=InvoiceId,InvoiceNumber,Supplier,SupplierNumber,SupplierSite,LegalEntity;invoiceLines:LineNumber,LineAmount,AccountingDate,DistributionCombination,invoiceLineProjectDff:InvoiceId,_TASK_ID_Display,_PROJECT_ID_Display&onlyData=true';

        //calling creation
        //HTTPrequestEndpont = '/fscmRestApi/resources/11.13.18.05/invoices/?q=CreationDate%3E2025-01-14T00:01:00.001Z&fields=InvoiceId,InvoiceNumber,CreationDate&limit=3&onlyData=true';

        // Create an HTTP request
        HttpRequest request = new HttpRequest();

      //  request.setEndpoint('callout:OracleCredential'+ HTTPrequestEndpont);
      request.setEndpoint('callout:OracleProductionExternalCredentials'+ HTTPrequestEndpont);
        request.setMethod('GET');
        
        // Send the request and get the response
        Http http = new Http();
        HttpResponse response = http.send(request);
        

        
        //creation
        
        // Check the response status code
        if (response.getStatusCode() == 200) {
            // Parse the response JSON to get the invoice data
            JSONParser parser = JSON.createParser(response.getBody());
            
            
            Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            
            /*
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
                //oracleProjectInvoice.oraclecreationdate__c = creationDate;

                // Add the new record to the list
                oracleProjectInvoices.add(oracleProjectInvoice);
            }
            insert oracleProjectInvoices;
            
            */

            System.debug(response.getBody());
            System.debug(m);
            //Map<String, Object> dim =  (Map<String, Object>)m.get('invoiceLines');
            //String ProjDffProjID = String.valueOf (m.get('_PROJECT_ID_Display'));
            // String ProjDffProjID = (String)dim.get('LineAmount');
            String getSupplierNumber = (String)m.get('SupplierNumber');
           // System.debug('Difff:  ' + ProjDffProjID);
            system.debug('SupplierNo'+ getSupplierNumber);
            System.debug(parser);

         

            while (parser.nextToken()!= null) {
                system.debug('parser LINE:  '+ parser.getText() + '-----' + parser.getCurrentName() + '-----' + parser.getCurrentToken());
                if ( parser.getCurrentName()  == 'InvoiceNumber' && parser.getText() != 'InvoiceNumber' ){
                    invoice.InvoiceNumber__c =  parser.getText() ;
                }
             
                if ( parser.getCurrentName()  == 'Supplier' && parser.getText() != 'Supplier' ){
                    invoice.OracleSupplierNumber__c = parser.getText() ;
                }
                if ( parser.getCurrentName()  == 'SupplierNumber' && parser.getText() != 'SupplierNumber' ){
                    invoice.OracleLegalEntity__c = parser.getText() ;
                }

                
                //if ( parser.getCurrentName()  == 'LineAmount' && parser.getText() != 'LineAmount' ){
                //    invoice.Paid_Amount__c = parser.getText() ;
                // 
                if ( parser.getCurrentName()  == 'AccountingDate' && parser.getText() != 'AccountingDate' ){    
                    invoice.OracleAccountingDate__c = parser.getDateValue() ;
                }
                if ( parser.getCurrentName()  == 'DistributionCombination' && parser.getText() != 'DistributionCombination' ){
                    invoice.DistributionCombination__c = parser.getText() ;
                }
                if ( parser.getCurrentName()  == 'LineAmount' && parser.getText() != 'LineAmount' ){
                    invoice.LineAmount__c = parser.getDecimalValue() ;
                }
                if ( parser.getCurrentName()  == 'LineNumber' && parser.getText() != 'LineNumber' ){
                    invoice.LineNumber__c = parser.getIntegerValue() ;
                }                
                if ( parser.getCurrentName()  == '_PROJECT_ID' && parser.getText() != '_PROJECT_ID' ){
                    invoice.LineProjectId__c = parser.getText() ;
                }                
                if ( parser.getCurrentName()  == '_PROJECT_ID_Display' && parser.getText() != '_PROJECT_ID_Display' ){
                    invoice.LineProjectDisplay__c = parser.getText() ;
                }
                if ( parser.getCurrentName()  == '_TASK_ID' && parser.getText() != '_TASK_ID' ){
                    invoice.LineTaskId__c = parser.getText() ;
                }
                if ( parser.getCurrentName()  == '_TASK_ID_Display' && parser.getText() != '_TASK_ID_Display' ){
                    invoice.LineTaskIdDisplay__c = parser.getText() ;
                }
                if ( parser.getCurrentName()  == 'AccountingDate' && parser.getText() != 'AccountingDate' ){
                    invoice.LineAccountingDate__c = parser.getDateValue() ;
                }



               /*
                if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                    while (parser.nextToken()!= null) {
                        if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                            InvoiceLine line = (InvoiceLine)parser.readValueAs(InvoiceLine.class);
                            System.debug('Line Number: ' + line.lineNumber);
                            System.debug('Line Amount: ' + line.LineAmount);
                            
                            for (InvoiceLineProjectDff projectDff : line.invoiceLineProjectDff) {
                                System.debug(projectDff);
                                System.debug('Project ID: '  +  projectDff.InvoiceId);
                                //System.debug('Amount: '  +  projectDff.LineAmount);
                               System.debug('Project IDDisplay: '  +  projectDff.PROJECT_ID_Display);
                            }
                        }
                    }
                }
                */
            }
            
        invoice.Paid_Amount__c = 100.0;
        invoice.Oracle_Description__c ='apex did this';
    

        try {
           update invoice;
        } catch (Exception e) {
            System.debug('Error updating invoice: ' + e.getMessage());
        }
    }
        }
    
    
    public class InvoiceLine {
        public String lineNumber;
        public String LineAmount;
        public List<InvoiceLineProjectDff> invoiceLineProjectDff;
    }
    
    public class InvoiceLineProjectDff {
       // public String PROJECT_ID;
       public String InvoiceId; 
       
       public String PROJECT_ID_Display; 
    }
}