@isTest
public with sharing class ProjectTeamBatchClassTest {

    @TestSetup
    static void setupData() {
        // Create a Project__c
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
    }

    @isTest
    static void testCreateBatchClass() {
        // Retrieve test data
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'Test Project' LIMIT 1];
        User user1 = [SELECT Id FROM User WHERE Email LIKE 'user1%' LIMIT 1];

        // Instantiate and execute the batch
        Test.startTest();
        projectTeam_createBatchClass createBatch = new projectTeam_createBatchClass();
        createBatch.projectId = project.Id;
        createBatch.userId = user1.Id;
        Database.executeBatch(createBatch);
        Test.stopTest();

        // Assert that AccountShare records are created
        List<AccountShare> accountShares = [SELECT Id, AccountAccessLevel FROM AccountShare WHERE UserOrGroupId = :user1.Id];
        System.assertEquals(1, accountShares.size(), 'One AccountShare should be created.');
        System.assertEquals('Edit', accountShares[0].AccountAccessLevel, 'Access level should be Edit.');
    }

    @isTest
    static void testUpdateBatchClass() {
        // Retrieve test data
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'Test Project' LIMIT 1];
        User user1 = [SELECT Id FROM User WHERE Email LIKE 'user1%' LIMIT 1];
        User user2 = [SELECT Id FROM User WHERE Email LIKE 'user2%' LIMIT 1];

        // Insert initial Project__Share for user1
        Project__Share projectShare = new Project__Share(
            ParentId = project.Id,
            UserOrGroupId = user1.Id,
            AccessLevel = 'Edit',
            RowCause = 'Manual'
        );
        insert projectShare;

        // Instantiate and execute the batch to update the shares to user2
        Test.startTest();
        projectTeam_updateBatchClass updateBatch = new projectTeam_updateBatchClass();
        updateBatch.projectId = project.Id;
        updateBatch.userId = user1.Id;
        updateBatch.newUserId = user2.Id;
        Database.executeBatch(updateBatch);
        Test.stopTest();

        // Assert that new Project__Share records are created for user2
        List<Project__Share> newProjectShares = [SELECT Id FROM Project__Share WHERE UserOrGroupId = :user2.Id];
        System.assertEquals(1, newProjectShares.size(), 'One Project__Share should be created for the new user.');
    }

    @isTest
    static void testDeleteBatchClass() {
        // Retrieve test data
        Project__c project = [SELECT Id FROM Project__c WHERE Name = 'Test Project' LIMIT 1];
        User user1 = [SELECT Id FROM User WHERE Email LIKE 'user1%' LIMIT 1];

        // Insert initial AccountShare and Project__Share for user1
        Project__Share projectShare = new Project__Share(
            ParentId = project.Id,
            UserOrGroupId = user1.Id,
            AccessLevel = 'Edit',
            RowCause = 'Manual'
        );
        insert projectShare;

        Account account = [SELECT Id FROM Account LIMIT 1];
        AccountShare accountShare = new AccountShare(
            AccountId = account.Id,
            UserOrGroupId = user1.Id,
            AccountAccessLevel = 'Edit',
            OpportunityAccessLevel = 'Edit',
            RowCause = 'Manual'
        );
        insert accountShare;

        // Instantiate and execute the batch to delete the shares
        Test.startTest();
        projectTeam_deleteBatchClass deleteBatch = new projectTeam_deleteBatchClass();
        deleteBatch.projectId = project.Id;
        deleteBatch.userId = user1.Id;
        Database.executeBatch(deleteBatch);
        Test.stopTest();

        // Assert that the Project__Share and AccountShare records are deleted
        List<Project__Share> projectShares = [SELECT Id FROM Project__Share WHERE UserOrGroupId = :user1.Id];
        System.assertEquals(0, projectShares.size(), 'Project__Share records should be deleted.');

        List<AccountShare> accountShares = [SELECT Id FROM AccountShare WHERE UserOrGroupId = :user1.Id];
        System.assertEquals(0, accountShares.size(), 'AccountShare records should be deleted.');
    }
}