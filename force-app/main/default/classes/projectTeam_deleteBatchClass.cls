public with sharing class projectTeam_deleteBatchClass implements Database.Batchable<Id>, Database.stateful {
    public Id projectId;
    public Id userId;

    // Start method retrieves all Account_Project__c records related to the projectId
    public Iterable<Id> start(Database.BatchableContext BC) {
        // Fetch related Account_Project__c records and extract Account__c IDs
        List<Account_Project__c> accountProjects = [SELECT Account__c FROM Account_Project__c WHERE Project__c = :projectId];
        Set<Id> accountIds = new Set<Id>();

        for (Account_Project__c ap : accountProjects) {
            accountIds.add(ap.Account__c);
        }

        System.debug('Account IDs to process for deletion: ' + accountIds);
        return accountIds;  // Return list of account IDs to process
    }

    // Execute method performs DML operations on the AccountShare and Project__Share records
    public void execute(Database.BatchableContext BC, List<Id> accountIds) {
        if (accountIds.isEmpty()) {
            System.debug('No Account IDs to process.');
            return;  // No account IDs to process
        }

        try {
            // Fetch and delete Project__Share records for the given project and user
            List<Project__Share> projectSharesToDelete = [SELECT Id FROM Project__Share WHERE ParentId = :projectId AND UserOrGroupId = :userId];
            if (!projectSharesToDelete.isEmpty()) {
                delete projectSharesToDelete;
                System.debug('Deleted Project__Share records for user: ' + userId);
            } else {
                System.debug('No Project__Share records found for deletion.');
            }

            // Fetch and delete AccountShare records linked to the accounts in the accountIds list
            List<AccountShare> accountSharesToDelete = [SELECT Id FROM AccountShare WHERE AccountId IN :accountIds AND UserOrGroupId = :userId];
            if (!accountSharesToDelete.isEmpty()) {
                delete accountSharesToDelete;
                System.debug('Deleted AccountShare records for user: ' + userId);
            } else {
                System.debug('No AccountShare records found for deletion.');
            }

        } catch (DmlException e) {
            System.debug('Error occurred while deleting records: ' + e.getMessage());
        }
    }

    // Finish method, for final cleanup or logging
    public void finish(Database.BatchableContext BC) {
        System.debug('Batch processing complete for projectId: ' + projectId + ', userId: ' + userId);
    }
}