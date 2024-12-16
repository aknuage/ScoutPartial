/**
 * @description       : 
 * @author            : NuAge - JP
 * @group             : 
 * @last modified on  : 07-28-2024
 * @last modified by  : NuAge - JP
**/
public with sharing class projectTeam_deleteLandAgentBatchClass implements Database.Batchable<Project_Team__c>, Database.stateful {
    public Id userId;
    public List<Project_Team__c> projectTeams;

    public Iterable<Project_Team__c> start(Database.BatchableContext BC){
        return projectTeams;
    }
    public void execute(Database.BatchableContext info, List<Project_Team__c> projectTeamRecords) {
        userId = projectTeams[0].User__c;
        List<Project__share> deleteProjectShareRecords = [SELECT Id, ParentId FROM Project__share WHERE ParentId =: projectTeamRecords[0].Project__c AND UserOrGroupId = :projectTeamRecords[0].User__c];

        if(deleteProjectShareRecords.size() > 0) delete deleteProjectShareRecords;
        System.debug('deleted proj shares: ' + deleteProjectShareRecords.size());
        List<Account_Project__c> accountProjects = [SELECT Id, Account__c, Project__c FROM Account_Project__c WHERE Project__c = :projectTeamRecords[0].Project__c];

        Set<Id> AccountIds = new Set<Id>();
        for(Account_Project__c ap: accountProjects){
            AccountIds.add(ap.Account__c);
        }

        List<AccountTeamMember> teamMembersToDelete = [SELECT Id FROM AccountTeamMember WHERE AccountId IN :AccountIds AND UserId = :projectTeamRecords[0].User__c];
        
        if (!teamMembersToDelete.isEmpty()) delete teamMembersToDelete;
        System.debug('deleted number of account team members: ' + teamMembersToDelete.size());

        List<AccountShare> accountShares = [SELECT Id FROM AccountShare WHERE AccountId IN :AccountIds AND UserOrGroupId = :projectTeamRecords[0].User__c];
        if(accountShares.size() > 0) delete accountShares;
        
    }
    public void finish(Database.BatchableContext info) {
        
    }
}

/*
    Callout to run batch class

    // This class can only handle one at a time :)
    projectTeam_deleteLandAgentBatchClass gdfc = new projectTeam_deleteLandAgentBatchClass();
    gdfc.projectTeams = ;
    Database.executeBatch(gdfc, 1);
*/