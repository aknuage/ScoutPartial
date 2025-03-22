public with sharing class HTTPbeta2OracleGetInvoicesQueueable implements Queueable, Database.AllowsCallouts {
    private Id recordId;
        public HTTPbeta2OracleGetInvoicesQueueable(Id recordId) {
      
            this.recordId = recordId;
        }
        
        public void execute(QueueableContext context) {
            OracleProjectInvoice__c invoice = [SELECT Id, Paid_Amount__c FROM OracleProjectInvoice__c WHERE Id = :recordId];
            invoice.Paid_Amount__c = 100.0;
            
            try {
                update invoice;
            } catch (Exception e) {
                System.debug('Error updating invoice: ' + e.getMessage());
            }
        }
    }