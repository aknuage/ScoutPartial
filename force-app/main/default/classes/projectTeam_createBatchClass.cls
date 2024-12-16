/**
 * @description       : 
 * @author            : NuAge - JP
 * @group             : 
 * @last modified on  : 09-22-2024
 * @last modified by  : NuAge - JP
**/
public with sharing class projectTeam_createBatchClass implements Database.Batchable<Account_Project__c>, Database.stateful {
    public Id projectId;
    public Id userId;
    public Iterable<Account_Project__c> start(Database.BatchableContext BC){
        List<Account_Project__c> accountProjects = [SELECT Id, Name, Account__c FROM Account_Project__c WHERE Project__c = :projectId];
        return accountProjects;
    }
    public void execute(Database.BatchableContext info, List<Account_Project__c> accountProjects) {
        // AccountShare
        List<AccountShare> accountShareRecords = new List<AccountShare>();
        for(Account_Project__c ap: accountProjects){
            AccountShare share = new AccountShare(
                AccountId = ap.Account__c,
                AccountAccessLevel = 'Edit',
                RowCause = 'Manual',
                UserOrGroupId = userId,
                OpportunityAccessLevel = 'None',
                CaseAccessLevel = 'None'
            );

            accountShareRecords.add(share);
        }
        System.debug('createBatchClass created num AccountShares: ' + accountShareRecords.size());

        if(accountShareRecords.size() > 0) insert accountShareRecords;
    }
    public void finish(Database.BatchableContext info) {
        
    }
}

/*
    Callout to run batch class

    // This class can only handle one at a time :)
    projectTeam_createBatchClass gdfc = new projectTeam_createBatchClass();
    gdfc.projectId = ;
    Database.executeBatch(gdfc, 25);
*/