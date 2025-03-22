/**
 * @description       : Batch class to process lease term construction.
 * @author            : akelly @ NuAge
 * @last modified on  : 12-11-2024
 **/
public with sharing class LeaseTermStartConstructionBatch implements Database.Batchable<sObject>, Database.Stateful {
    private Set<Id> projectIds;

    public LeaseTermStartConstructionBatch(Set<Id> projectIds) {
        this.projectIds = projectIds;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, Construction_Start_Date__c, (SELECT Id, Status__c, Payment_Type__c, Due_Date__c '
        + 'FROM Payments_Contract_Parties__r WHERE Status__c != \'Paid\' '
        + 'AND (Payment_Type__c = \'Amendment Payment\' OR Payment_Type__c = \'Development Payment\')) '
        + 'FROM Project__c WHERE Id IN :projectIds';
        System.debug('query: ' + query);
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext info, List<Project__c> scope) {
        System.debug('scope size: ' + scope.size());
        Map<Id, Project__c> projectMap = new Map<Id, Project__c>();
        Map<Id, Term__c> projectToTermMap = new Map<Id, Term__c>();
        Map<Id, Land_Owner_Payment__c> paymentsToUpdate = new Map<Id, Land_Owner_Payment__c>();
        
        // Collect Payments whose Due Date is greater than start of construction date
        for (Project__c project : scope) {
            for (Land_Owner_Payment__c lop : project.Payments_Contract_Parties__r) {
                    Date startDate = project.Construction_Start_Date__c;
                    // If Payment is later than Term's start of construction date, terminate the payment
                    if (lop.Due_Date__c > startDate) {
                        lop.Status__c = 'Terminated';
                        paymentsToUpdate.put(lop.Id, lop);
                    }
                }
        }
            
        System.debug('number of payments to terminate: ' + paymentsToUpdate.values().size());
            
        if (!paymentsToUpdate.isEmpty()) update paymentsToUpdate.values();
    }
    
    

    public void finish(Database.BatchableContext info) {
        System.debug('Batch process completed.');
    }
}