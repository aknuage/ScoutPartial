/**
 * @description       : 
 * @author            : NuAge - JP
 * @group             : 
 * @last modified on  : 09-22-2024
 * @last modified by  : NuAge - JP
**/
public with sharing class projectTeam_insertLandAgentBatchClass implements Database.Batchable<Project_Team__c>, Database.stateful {
    public Id userId;
    public List<Project_Team__c> projectTeams;

    public Iterable<Project_Team__c> start(Database.BatchableContext BC){
        return projectTeams;
    }
    public void execute(Database.BatchableContext info, List<Project_Team__c> projectTeamRecords) {
        Project__share projectShare;
        for (Project_Team__c pt : projectTeamRecords) {
            userId = pt.user__c;
            projectShare = new Project__share(
                AccessLevel = 'Edit',
                ParentId = pt.Project__c,
                RowCause = 'Project_Team_Member_Access__c',
                UserOrGroupId = userId
            );
            System.debug('inserted project share: ' + JSON.serializePretty(projectShare));
            insert projectShare;
        }
        
        // Query child Account Projects
        List<Account_Project__c> accountProjects = [
            SELECT Id, Account__c
            FROM Account_Project__c
            WHERE Project__c = :projectTeams[0].Project__c
        ];

        List<AccountTeamMember> teamMembers = new List<AccountTeamMember>();
        
        // Create Account Team records from Account Projects gathered
        for (Account_Project__c ap : accountProjects) {
            teamMembers.add(new AccountTeamMember (
                AccountAccessLevel = 'Edit',
                AccountId = ap.Account__c,
                TeamMemberRole = 'Land Agent',
                UserId = userId,
                OpportunityAccessLevel = 'None',
                CaseAccessLevel = 'None'
            ));
        }
        // Insert
        if (!teamMembers.isEmpty()) insert teamMembers;
        System.debug('inserted: ' + teamMembers.size());
        
        
    }
    public void finish(Database.BatchableContext info) {
        
    }
}
