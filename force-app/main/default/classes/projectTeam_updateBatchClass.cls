public with sharing class projectTeam_updateBatchClass implements Database.Batchable<Id>, Database.stateful {
    public Id projectId;
    public Id userId;
    public Id newUserId;

    // Start method retrieves the list of account IDs to process
    public Iterable<Id> start(Database.BatchableContext BC) {
        // Fetch and delete old Project__Share records for the old user
        List<Project__Share> projectSharesToDelete = [SELECT Id FROM Project__Share WHERE ParentId = :projectId AND UserOrGroupId = :userId];
        
        // If records exist, proceed to delete
        if (!projectSharesToDelete.isEmpty()) {
            try {
                delete projectSharesToDelete;
                System.debug('Deleted Project__Share records for old user: ' + userId);
            } catch (DmlException e) {
                System.debug('Error deleting Project__Share records: ' + e.getMessage());
            }
        } else {
            System.debug('No Project__Share records found for deletion.');
        }

        // Fetch related Account_Project__c records and extract Account__c IDs
        List<Account_Project__c> accountProjects = [SELECT Account__c FROM Account_Project__c WHERE Project__c = :projectId];
        Set<Id> accountIds = new Set<Id>();

        for (Account_Project__c ap : accountProjects) {
            accountIds.add(ap.Account__c);
        }

        System.debug('Account IDs to process for new user shares: ' + accountIds);
        return accountIds;  // Return list of account IDs to process
    }

    // Execute method creates new shares for the new user
    public void execute(Database.BatchableContext info, List<Id> accountIds) {
        if (accountIds.isEmpty()) {
            System.debug('No Account IDs to process.');
            return;
        }

        // Create new Project__Share records for the new user
        List<Project__Share> projectSharesToInsert = new List<Project__Share>();
        projectSharesToInsert.add(new Project__Share(
            AccessLevel = 'Edit',
            ParentId = projectId,
            RowCause = 'Project_Team_Member_access__c',
            UserOrGroupId = newUserId
        ));

        try {
            if (!projectSharesToInsert.isEmpty()) {
                insert projectSharesToInsert;
                System.debug('Inserted Project__Share records for new user: ' + newUserId);
            }
        } catch (DmlException e) {
            System.debug('Error inserting Project__Share records: ' + e.getMessage());
        }

        // Create new AccountShare records for the new user
        List<AccountShare> accountSharesToInsert = new List<AccountShare>();
        for (Id accountId : accountIds) {
            accountSharesToInsert.add(new AccountShare(
                AccountId = accountId,
                AccountAccessLevel = 'Edit',
                RowCause = 'Manual',
                UserOrGroupId = newUserId,
                OpportunityAccessLevel = 'None',
                CaseAccessLevel = 'None'
            ));
        }

        try {
            if (!accountSharesToInsert.isEmpty()) {
                insert accountSharesToInsert;
                System.debug('Inserted AccountShare records for new user: ' + newUserId);
            }
        } catch (DmlException e) {
            System.debug('Error inserting AccountShare records: ' + e.getMessage());
        }
    }

    // Finish method for final logging or cleanup
    public void finish(Database.BatchableContext BC) {
        System.debug('Batch processing complete for Project: ' + projectId + ', updated from old user: ' + userId + ' to new user: ' + newUserId);
    }
}