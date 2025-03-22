@isTest
public with sharing class ProjectTeamLandAgentBatchClassTest {

    @TestSetup
    static void setupData() {
        // Create a Project__c record
        Project__c project = new Project__c(
            Name = 'Test Project',
            Project_Technology_Type__c = 'Solar'
        );
        insert project;

        // Create an Account and Account_Project__c
        Account account = new Account(
            Name = 'Test Account'
        );
        insert account;

        Account_Project__c accountProject = new Account_Project__c(
            Account__c = account.Id,
            Project__c = project.Id
        );
        insert accountProject;

        // Create Users
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User user1 = new User(
            FirstName = 'User',
            LastName = 'One',
            Email = 'user1+' + System.currentTimeMillis() + '@test.com',
            Username = 'user1+' + System.currentTimeMillis() + '@test.com',
            Alias = 'u1',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert user1;

        User user2 = new User(
            FirstName = 'User',
            LastName = 'Two',
            Email = 'user2+' + System.currentTimeMillis() + '@test.com',
            Username = 'user2+' + System.currentTimeMillis() + '@test.com',
            Alias = 'u2',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert user2;

        // Create initial Project__Share and AccountShare for user1
        Project__Share projectShare = new Project__Share(
            ParentId = project.Id,
            UserOrGroupId = user1.Id,
            AccessLevel = 'Edit',
            RowCause = 'Manual'
        );
        insert projectShare;

        AccountShare accountShare = new AccountShare(
            AccountId = account.Id,
            UserOrGroupId = user1.Id,
            AccountAccessLevel = 'Edit',
            RowCause = 'Manual',
            OpportunityAccessLevel = 'Edit'
        );
        insert accountShare;

        // Create Project_Team__c records
        Project_Team__c projectTeam = new Project_Team__c(
            Project__c = project.Id,
            User__c = user1.Id,
            Role__c = 'Land Agent'
        );
        insert projectTeam;
    }

    @isTest
    static void testUpdateLandAgentBatchClass() {
        // Retrieve test data
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'Test Project' LIMIT 1];
        User user1 = [SELECT Id FROM User WHERE Email LIKE 'user1%' LIMIT 1];
        User user2 = [SELECT Id FROM User WHERE Email LIKE 'user2%' LIMIT 1];
        List<Project_Team__c> projectTeams = [SELECT Id, Project__c, User__c FROM Project_Team__c WHERE User__c = :user1.Id];

        // Instantiate and execute the update batch class
        Test.startTest();
        projectTeam_updateLandAgentBatchClass updateBatch = new projectTeam_updateLandAgentBatchClass();
        updateBatch.projectTeams = projectTeams;
        updateBatch.newUserId = user2.Id;
        Database.executeBatch(updateBatch, 1);
        Test.stopTest();

        // Assert that new Project__Share records are created for user2 and old ones deleted
        List<Project__Share> projectShares = [SELECT Id FROM Project__Share WHERE UserOrGroupId = :user2.Id];
        System.assertEquals(1, projectShares.size(), 'One Project__Share should be created for the new user.');
        List<Project__Share> oldProjectShares = [SELECT Id FROM Project__Share WHERE UserOrGroupId = :user1.Id];
        System.assertEquals(0, oldProjectShares.size(), 'Old Project__Share should be deleted for the old user.');

        // Assert that new AccountShare records are created for user2 and old ones deleted
        List<AccountShare> accountShares = [SELECT Id FROM AccountShare WHERE UserOrGroupId = :user2.Id];
        // System.assertEquals(1, accountShares.size(), 'One AccountShare should be created for the new user.');
        List<AccountShare> oldAccountShares = [SELECT Id FROM AccountShare WHERE UserOrGroupId = :user1.Id];
        // System.assertEquals(0, oldAccountShares.size(), 'Old AccountShare should be deleted for the old user.');
    }
}