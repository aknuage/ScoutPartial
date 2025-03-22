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

        List<Account_Project__c> accountProjects = [SELECT Id, Account__c, Project__c FROM Account_Project__c WHERE Project__c = :projectTeamRecords[0].Project__c];

        Set<Id> AccountIds = new Set<Id>();
        for(Account_Project__c ap: accountProjects){
            AccountIds.add(ap.Account__c);
        }

        List<AccountTeamMember> teamMembersToDelete = [SELECT Id FROM AccountTeamMember WHERE AccountId IN :AccountIds AND UserId = :projectTeamRecords[0].User__c];
        
        if (!teamMembersToDelete.isEmpty()) 
        {
            // delete teamMembersToDelete;
            if (!AccountIds.isEmpty()) {
                Map<Id, List<sObject>> accountChildren = checkChildObjects(AccountIds, userId);
                if (!accountChildren.isEmpty()) {
                    // Ensures access is preserved before deleting Account Team Members
                    AccountTeamMemberDeletionHandler.deleteAccountTeamMembers(accountChildren, userId);
                } else {
                    delete teamMembersToDelete;
                }
            }
        }

        List<AccountShare> accountShares = [SELECT Id FROM AccountShare WHERE AccountId IN :AccountIds AND UserOrGroupId = :projectTeamRecords[0].User__c];
        if(accountShares.size() > 0) 
        {
            // Force delete and recalculate shares for Accounts with Child Objects
            delete accountShares;
        }
    }

    public void finish(Database.BatchableContext info) {}

    private Map<Id, List<sObject>> checkChildObjects(Set<Id> accountIds, Id ownerUserId)
    {
        Map<Id, List<sObject>> resultMap = new Map<Id, List<sObject>>();
        
        List<Account> accounts = [SELECT Id,
                (SELECT Id, OwnerId FROM Opportunities LIMIT 1),
                (SELECT Id, OwnerId  FROM Contacts LIMIT 1),
                (SELECT Id, OwnerId FROM Cases LIMIT 1)
            FROM Account
            WHERE Id IN :accountIds];

        // Boolean hasOpportunities = !a.Opportunities.isEmpty();
        // Boolean hasContacts = !a.Contacts.isEmpty();
        // Boolean hasCases = !a.Cases.isEmpty();
        
        for (Account a : accounts)
        {
            for (Contact c : a.Contacts)
            {
                if (c.OwnerId == ownerUserId)
                {
                    if (!resultMap.containsKey(a.Id))
                    {
                        resultMap.put(a.Id, new List<sObject>());
                    }
                    resultMap.get(a.Id).add(c);
                }
            }
        }
        return resultMap;
    }
}

/*
    Callout to run batch class

    // This class can only handle one at a time :)
    projectTeam_deleteLandAgentBatchClass gdfc = new projectTeam_deleteLandAgentBatchClass();
    gdfc.projectTeams = ;
    Database.executeBatch(gdfc, 1);
*/