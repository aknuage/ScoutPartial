/**
 * @description       : Batch class to handle Lease Terms which are updated to "Start of Construction"
 * status, and whose Start Date is not null. Query all Land Owner Payments of type "Development" or
 * "Amendment", and terminate all related Payments that are greater than the Term's start date.
 * 
 * @author            : akelly @ NuAge : December 11, 2024
 * @last modified on  : 12-11-2024
 **/
public with sharing class LeaseTermStartConstructionBatch implements Database.Batchable<sObject>, Database.Stateful {
    private Set<Id> termProjectIds; // Parent Project IDs of the Terms that kicked off the Batch job

    public LeaseTermStartConstructionBatch(Set<Id> termProjectIds) {
        this.termProjectIds = termProjectIds;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, (SELECT Id, Status__c, Payment_Type__c, Due_Date__c '
        + 'FROM Payments_Contract_Parties__r WHERE Status__c != \'Paid\' '
        + 'AND (Payment_Type__c = \'Amendment Payment\' OR Payment_Type__c = \'Development Payment\')) '
        + 'FROM Project__c WHERE Id IN :termProjectIds';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext info, List<sObject> scope) {
        List<Project__c> projects = (List<Project__c>) scope;
        
        Map<Id, Project__c> projectMap = new Map<Id, Project__c>();
        Map<Id, Term__c> projectToTermMap = new Map<Id, Term__c>();
        Map<Id, Land_Owner_Payment__c> paymentsToUpdate = new Map<Id, Land_Owner_Payment__c>();
        // System.debug('scope size: ' + scope.size());
        
        projectMap = getProjectMap(projects);
        projectToTermMap = getTermsProjectMap(termProjectIds);

        for (Project__c project : projectMap.values()) {
            for (Land_Owner_Payment__c lop : project.Payments_Contract_Parties__r) {
                // Collect Payments whose Due Date is in the future of Term's start of construction date
                if (projectToTermMap.get(project.Id).Start_of_Construction_Date__c != null) {
                    Date startDate = projectToTermMap.get(project.Id).Start_of_Construction_Date__c;
                    // If Payment is later than Term's start of construction date, terminate the payment
                    if (lop.Due_Date__c > startDate) {
                        lop.Status__c = 'Terminated';
                        paymentsToUpdate.put(lop.Id, lop);
                    }
                }
            }
        }

        System.debug('number of payments to terminate: ' + paymentsToUpdate.values().size());

        if (!paymentsToUpdate.isEmpty()) update paymentsToUpdate.values();
        
    }
    
    /**
     * Loop through Projects in scope and populate a map of ID to Project for reference purposes.
     * @param - List<Project__c> list of projects in scope
     * @return - Map<Id, Project__c>
     * @author - akelly @ NuAge : December 12, 2024
     */
    private static Map<Id, Project__c> getProjectMap(List<Project__c> projects)
    {
        Map<Id, Project__c> returnValue = new Map<Id, Project__c>();
        for (Project__c project : projects)
        {
            returnValue.put(project.Id, project);
        }
        return returnValue;
    }

    /**
     * Loop through Terms that triggered this batch execution and return map of Project ID to Term for
     * reference purposes further down the line.
     * @param - Set<Id> Set of Project IDs from the Terms that triggered batch job.
     * @return - Map<Id, Term__c>
     * @author - akelly @ NuAge : December 12, 2024
     */
    private static Map<Id, Term__c> getTermsProjectMap(Set<Id> termProjectIds)
    {
        Map<Id, Term__c> returnValue = new Map<Id, Term__c>();
        for (Term__c term : [Select Project__c, Start_of_Construction_Date__c FROM Term__c WHERE Project__c IN :termProjectIds])
        {
            returnValue.put(term.Project__c, term);
        }
        return returnValue;
    }


    public void finish(Database.BatchableContext info) {
        System.debug('Batch process completed.');
    }
}
