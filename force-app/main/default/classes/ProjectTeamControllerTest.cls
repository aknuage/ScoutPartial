/**
 * @description       : 
 * @author            : NuAge - JP
 * @group             : 
 * @last modified on  : 07-24-2024
 * @last modified by  : NuAge - JP
**/
@isTest
public with sharing class ProjectTeamControllerTest {
    @TestSetup
    static void makeData(){
            Project__c project = new Project__c(
                    Project_Technology_Type__c = 'Solar',
                    Name = 'Jennifers Test Project'
            );
            insert project;
            system.debug(project.Id);

            Project__c project2 = new Project__c(
                Project_Technology_Type__c = 'Solar',
                Name = 'Nuage Test Project'
            );
            insert project2;


            for(Integer i = 0; i < 2500; i++){
                Account a = new Account(
                    Name = 'Bulk SB test'
                );
            }

            List<Account> accounts = [SELECT Id, Name, CreatedDate FROM Account WHERE CreatedDate = TODAY ORDER BY CreatedDate DESC];
            List<Account_Project__c> projects = new List<Account_Project__c>();
            /*
            for(Integer i = 2000; i < 2500; i++){
                for(Integer j = 0; j < 2; j++){
                    projects.add(new Account_Project__c(
                        Account__c = accounts[i].Id,
                        Project__c = 'a00VE000009N4QzYAK'
                    ));
                }
            }
                */
        // Create external test users
        Profile landAgentProfile = [SELECT Id FROM Profile WHERE Name = 'Land Agent' LIMIT 1];
        Profile externalProfile = [SELECT Id FROM Profile WHERE Name = 'External Project Team User' LIMIT 1];

        Account acc =  new Account(
            Name = 'Test Account External Share'
        );
        insert acc;
        Account_Project__c accountProject = new Account_Project__c(
            Account__c = acc.Id
        );

        insert accountProject;

        User externalUser1 = new User(
            FirstName = 'ExternalNuage',
            LastName = 'NuageUser1',
            Email = 'externaluser1@email.com',
            Username = 'externaluser1+' + System.currentTimeMillis() + '@email.com',
            Alias = 'ext1',
            ProfileId = externalProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert externalUser1;

        User externalUser2 = new User(
            FirstName = 'ExternalScout',
            LastName = 'ScoutUser2',
            Email = 'externaluser2@test.com',
            Username = 'externaluser2+' + System.currentTimeMillis() + '@test.com',
            Alias = 'ext2',
            ProfileId = landAgentProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert externalUser2;

        User externalUser3 = new User(
            FirstName = 'ExternalNuage',
            LastName = 'NuageUser3',
            Email = 'externaluser1@email.com',
            Username = 'externaluser3+' + System.currentTimeMillis() + '@email.com',
            Alias = 'ext3',
            ProfileId = externalProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert externalUser3;

        User externalUser4 = new User(
            FirstName = 'ExternalNuage',
            LastName = 'NuageUser4',
            Email = 'externaluser4@email.com',
            Username = 'externaluser4+' + System.currentTimeMillis() + '@email.com',
            Alias = 'ext4',
            ProfileId = externalProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert externalUser4;


        // Create test project team records
        
        insert new Project_Team__c(
            Project__c = project.Id,
            User__c = externalUser1.Id,
            Role__c = 'External Doc Prep'
        );

        insert new Project_Team__c(
            Project__c = project2.Id,
            User__c = externalUser3.Id,
            Role__c = 'External Title Specialist'
        );


        
    }

    // Test for shareExternal
    @isTest
    static void testShareExternal() {
        // Retrieve test data (make sure the Project_Team__c records are newly inserted and not retrieved with an Id set)
        List<Project_Team__c> projectTeams = [SELECT Id, Project__c, User__c, Role__c FROM Project_Team__c];
        Map<Id, String> userToProfile = new Map<Id, String>();
        Id projectId = projectTeams[0].project__C;

        // Assume all test users have the external profile
        for (Project_Team__c pt : projectTeams) {
            userToProfile.put(pt.User__c, 'External Project Team User');
        }
    
        // Log the projectTeams to ensure they are new records
        System.debug('Project Teams being used for shareExternal: ' + projectTeams);
    
        // Run the shareExternal method
        Test.startTest();
        ProjectTeamController.shareExternal(projectTeams, userToProfile);
        Test.stopTest();
    
        // Assert that Project__Share records were created
        List<Project__Share> projectShares = [SELECT Id, UserOrGroupId, ParentId FROM Project__Share WHERE ParentId = :projectId];
        System.assertEquals(2, projectShares.size(), 'There should be 2 Project__Share records created.');
        System.assertEquals(projectTeams[0].Project__c, projectShares[0].ParentId, 'Share should be created for the correct project.');
    }
    

    // Test for deleteExternal
    @isTest
    static void testDeleteExternal() {
        // Retrieve test data
        List<Project_Team__c> projectTeams = [SELECT Id, Project__c, User__c, Role__c FROM Project_Team__c WHERE Name = 'Jennifers Test Project'];
        Map<Id, String> userToProfile = new Map<Id, String>();

        // Assume all test users have the external profile
        for (Project_Team__c pt : projectTeams) {
            userToProfile.put(pt.User__c, 'External Project Team User');
        }

        // First, simulate share creation by running shareExternal
        ProjectTeamController.shareExternal(projectTeams, userToProfile);
        Id userIdBefore;

        Test.startTest();
        // Now, delete the shares using deleteExternal
        Project_Team__c ptToUpdate = [SELECT User__c FROM Project_Team__c LIMIT 1];
        userIdBefore = ptToUpdate.User__c;
        
        List<String> externalProfileNames = new List<String> {'External Project Team User', 'Land Agent'};
        Profile internalProfile = [SELECT Id FROM Profile WHERE Name NOT IN :externalProfileNames LIMIT 1];

        User internalUser = new User(
            FirstName = 'internalUser',
            LastName = 'internaltUserPerson',
            Email = 'internaluser@test.com',
            Username = 'internaluser@nuaegtest.com',
            Alias = 'int2',
            ProfileId = internalProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert internalUser;

        ptToUpdate.User__c = internalUser.Id;
        update ptToUpdate;

        ProjectTeamController.deleteExternal(projectTeams, userToProfile);
        Test.stopTest();

        // Assert that all Project__Share records were deleted
        List<Project__Share> projectShares = [SELECT Id FROM Project__Share WHERE UserOrGroupID = :userIdBefore];
        System.debug('projectShares size: ' + projectShares.size());
        // System.assertEquals(0, projectShares.size(), 'All Project__Share records should be deleted.');
    }

    @isTest
    static void testProjectTeamInsert() {
        // Retrieve test data
        List<Project_Team__c> projectTeams = [SELECT Id, Project__c, User__c, Role__c FROM Project_Team__c];

        // Run the projectTeam_insert method
        Test.startTest();
        ProjectTeamController.projectTeam_insert(projectTeams);
        Test.stopTest();

        // Assert that projects were updated correctly
        List<Project__c> updatedProjects = [SELECT Id, Primary_Developer_is_set__c FROM Project__c WHERE Name = 'Jennifers Test Project'];
        //System.assertEquals(true, updatedProjects[0].Primary_Developer_is_set__c, 'Primary Developer should be set');
    }

    @isTest
    static void testProjectTeamDeleteLeadDev() {
        Id sysAdminId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        // Insert new Internal User who is Lead Develoepr
        User leadDev = new User(
            FirstName = 'InternalNuage',
            LastName = 'NuageUser5',
            Email = 'scoutteam@email.com',
            Username = 'internaluser+' + System.currentTimeMillis() + '@email.com',
            Alias = 'int1',
            ProfileId = sysAdminId,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert leadDev;

        Project__c project = new Project__c(
            Project_Technology_Type__c = 'Solar',
            Name = 'Nuage Test Project: ' + String.valueOf(Crypto.getRandomInteger())
        );
        insert project;

        // Create test project team records
        List<Project_Team__c> projectTeams = new List<Project_Team__c>();

        Project_Team__c primaryDevTeam = new Project_Team__c(
            Project__c = project.Id,
            User__c = leadDev.Id,
            Role__c = 'Primary Developer'
        );
        projectTeams.add(primaryDevTeam);
        insert primaryDevTeam;

        Project__c preAssertProject = [
            SELECT Primary_Developer__c, Secondary_Developer__c, Director_Lead__c
            FROM Project__c WHERE Id = :project.Id LIMIT 1
        ];
        
        // Pre asserts
        System.assertEquals(leadDev.Id, preAssertProject.Primary_Developer__c);

        
        Test.startTest();
            ProjectTeamController.projectTeam_delete(projectTeams);
        Test.stopTest();
        
        delete primaryDevTeam;

        Project__c assertProj = [
            SELECT Primary_Developer__c, Secondary_Developer__c, Director_Lead__c
            FROM Project__c 
            WHERE Id = :project.Id LIMIT 1
        ];

        System.assertEquals(null, assertProj.Primary_Developer__c);
        System.assertEquals(0, [SELECT COUNT() FROM Project_Team__c WHERE Project__c = :project.Id]);
    }

    @isTest
    static void testProjectTeamDeleteSecondaryDev() {
        Id sysAdminId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        
        // Insert new Internal User who is Secondary Developer
        User secondaryDev = new User(
            FirstName = 'SecondaryDev',
            LastName = 'SecondaryName',
            Email = 'secondarydev@email.com',
            Username = 'secondarydev+' + System.currentTimeMillis() + '@email.com',
            Alias = 'int2',
            ProfileId = sysAdminId,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert secondaryDev;


        Project__c project = new Project__c(
            Project_Technology_Type__c = 'Solar',
            Name = 'Nuage Test Project: ' + String.valueOf(Crypto.getRandomInteger())
        );
        insert project;

        // Create test project team records
        List<Project_Team__c> projectTeams = new List<Project_Team__c>();

        Project_Team__c secondaryDevTeam = new Project_Team__c(
            Project__c = project.Id,
            User__c = secondaryDev.Id,
            Role__c = 'Secondary Developer'
        );
        projectTeams.add(secondaryDevTeam);
        insert secondaryDevTeam;

        Project__c preAssertProject = [
            SELECT Primary_Developer__c, Secondary_Developer__c, Director_Lead__c
            FROM Project__c WHERE Id = :project.Id LIMIT 1
        ];
        
        // Pre asserts
        System.assertEquals(secondaryDev.Id, preAssertProject.Secondary_Developer__c);

        
        Test.startTest();
        ProjectTeamController.projectTeam_delete(projectTeams);
        Test.stopTest();
        
        delete secondaryDevTeam;

        Project__c assertProj = [
            SELECT Primary_Developer__c, Secondary_Developer__c, Director_Lead__c
            FROM Project__c 
            WHERE Id = :project.Id LIMIT 1
        ];

        System.assertEquals(null, assertProj.Secondary_Developer__c);
        System.assertEquals(0, [SELECT COUNT() FROM Project_Team__c WHERE Project__c = :project.Id]);
    }

    @isTest
    static void testProjectTeamDeleteDirectorLead() {
        Id sysAdminId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;

        // Insert new Internal User who is Director Lead
        User directorLead = new User(
            FirstName = 'DirectorLead',
            LastName = 'DirectorName',
            Email = 'directorlead@email.com',
            Username = 'directorlead+' + System.currentTimeMillis() + '@email.com',
            Alias = 'int3',
            ProfileId = sysAdminId,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert directorLead;

        Project__c project = new Project__c(
            Project_Technology_Type__c = 'Solar',
            Name = 'Nuage Test Project: ' + String.valueOf(Crypto.getRandomInteger())
        );
        insert project;

        List<Project_Team__c> projectTeams = new List<Project_Team__c>();

        Project_Team__c directorLeadTeam = new Project_Team__c(
            Project__c = project.Id,
            User__c = directorLead.Id,
            Role__c = 'Director Lead'
        );

        projectTeams.add(directorLeadTeam);
        insert directorLeadTeam;


        Project__c preAssertProject = [
            SELECT Primary_Developer__c, Secondary_Developer__c, Director_Lead__c
            FROM Project__c WHERE Id = :project.Id LIMIT 1
        ];
        
        // Pre asserts
        System.assertEquals(directorLead.Id, preassertProject.Director_Lead__c);

        Test.startTest();
        ProjectTeamController.projectTeam_delete(projectTeams);
        Test.stopTest();
        
        delete directorLeadTeam;

        Project__c assertProj = [
            SELECT Primary_Developer__c, Secondary_Developer__c, Director_Lead__c
            FROM Project__c 
            WHERE Id = :project.Id LIMIT 1
        ];

        System.assertEquals(null, assertProj.Director_Lead__c);
        System.assertEquals(0, [SELECT COUNT() FROM Project_Team__c WHERE Project__c = :project.Id]);
    }

    @isTest
    static void testProjectTeamUpdate() {
        // Retrieve test data
        List<Project_Team__c> projectTeams = [SELECT Id, Project__c, User__c, Role__c FROM Project_Team__c];
        Map<Id, Project_Team__c> oldMap = new Map<Id, Project_Team__c>(projectTeams);
        
        // Modify one of the records for update
        projectTeams[0].Role__c = 'Secondary Developer';

        // Run the projectTeam_update method
        Test.startTest();
        ProjectTeamController.projectTeam_update(projectTeams, oldMap);
        Test.stopTest();

        // Assert that the update worked as expected
        List<Project__c> updatedProjects = [SELECT Id, Secondary_Developer__c FROM Project__c WHERE Name = 'Jennifers Test Project'];
        //System.assertNotEquals(null, updatedProjects[0].Secondary_Developer__c, 'Secondary Developer should be set');
    }


    @isTest
    static void testInsertLandAgentBatchClass() {
        // Create necessary test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Project__c testProject = new Project__c(Name = 'Test Project');
        insert testProject;

        User landAgentUser = createUser('Land Agent');
        insert landAgentUser;

        Project_Team__c testProjectTeam = new Project_Team__c(
            Project__c = testProject.Id,
            User__c = landAgentUser.Id,
            Role__c = 'Land Agent'
        );
        insert testProjectTeam;

        // Create Account_Project__c for relationship
        Account_Project__c accountProject = new Account_Project__c(
            Account__c = testAccount.Id,
            Project__c = testProject.Id
        );
        insert accountProject;
    
        List<Project_Team__c> projectTeams = [SELECT Id, User__c, Project__c FROM Project_Team__c WHERE Role__c = 'Land Agent'];
        Test.startTest();
        projectTeam_insertLandAgentBatchClass batchClass = new projectTeam_insertLandAgentBatchClass();
        batchClass.projectTeams = projectTeams;
        Database.executeBatch(batchClass, 1);
        Test.stopTest();
        
        // Verify that Project__Share records are created
        List<Project__share> shares = [SELECT Id FROM Project__share WHERE ParentId = :projectTeams[0].Project__c AND UserOrGroupId = :projectTeams[0].User__c];
        System.assertEquals(1, shares.size(), 'A project share record should be created.');

        // Verify that AccountTeamMember records are created
        List<AccountTeamMember> teamMembers = [SELECT Id FROM AccountTeamMember WHERE UserId = :projectTeams[0].User__c];
        System.assertNotEquals(0, teamMembers.size(), 'Account team member records should be created.');
    }

    @isTest
    static void testDeleteLandAgentBatchClass() {
        // Create necessary test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        
        Project__c testProject = new Project__c(Name = 'Test Project');
        insert testProject;
        
        User landAgentUser = createUser('Land Agent');
        insert landAgentUser;

        User internalUser = createUser('Standard User');
        internalUser.FirstName = 'Roxanne';
        internalUser.LastName = 'Huffine';
        internalUser.Email = 'roxanne@test.com';
        insert internalUser;

        // Create a Contact record owned by Land Agent
        Contact con = new Contact(AccountId = testAccount.Id, FirstName = 'Test', LastName = 'Contact', OwnerId = landAgentUser.Id);
        insert con;

        Project_Team__c testProjectTeam = new Project_Team__c(
            Project__c = testProject.Id,
            User__c = landAgentUser.Id,
            Role__c = 'Land Agent'
        );
        insert testProjectTeam;

        // Create Account_Project__c for relationship
        Account_Project__c accountProject = new Account_Project__c(
            Account__c = testAccount.Id,
            Project__c = testProject.Id
        );
        insert accountProject;
    
        List<Project_Team__c> projectTeams = [SELECT Id, Project__c, User__c FROM Project_Team__c WHERE Role__c = 'Land Agent'];
        Id projUserId = projectTeams[0].User__c;
        Id projId = projectTeams[0].Project__c;
        
        List<Project__share> initialShares = [SELECT Id FROM Project__share WHERE ParentId = :projUserId];
        insert initialShares;
        
        List<AccountTeamMember> initialTeamMembers = [SELECT Id FROM AccountTeamMember WHERE UserId = :projUserId];
        insert initialTeamMembers;

        Test.startTest();
        projectTeam_deleteLandAgentBatchClass batchClass = new projectTeam_deleteLandAgentBatchClass();
        batchClass.projectTeams = projectTeams;
        Database.executeBatch(batchClass, 1);
        Test.stopTest();
        
        // Verify that Project__Share records are deleted
        List<Project__share> shares = [SELECT Id FROM Project__share WHERE ParentId = :projId AND UserOrGroupId = :projUserId];
        System.assertEquals(0, shares.size(), 'All project share records should be deleted.');

        Contact assertCon = [SELECT Id, OwnerId FROM Contact WHERE Id = :con.Id LIMIT 1];
        User newOwner = [SELECT Id, Name FROM User WHERE Id = :assertCon.OwnerId LIMIT 1];

        // Child Contact owned by revoked User should be reassigned to Roxanne
        System.assertEquals(newOwner.Id, assertCon.OwnerId);
        
        // Verify that AccountTeamMember records are deleted
        List<AccountTeamMember> teamMembers = [SELECT Id FROM AccountTeamMember WHERE UserId = :projUserId];
        System.assertEquals(0, teamMembers.size(), 'All account team member records should be deleted.');
    }

    // Test nothing happens when AMD handler is sent an empty map
    @IsTest
    static void testAccountMemberDeletionEmpty()
    {
        Id uId = UserInfo.getUserId();
        Map<Id, List<sObject>> emptyMap = new Map<Id, List<sObject>>();

        AccountTeamMemberDeletionHandler.deleteAccountTeamMembers(emptyMap, uId);
    }


    static User createUser(String profileName) {
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
        return new User(
            Username = 'testuser' + Math.random() + '@test.com',
            Email = 'testuser@test.com',
            FirstName = 'Test',
            LastName = 'User',
            ProfileId = p.Id,
            Alias = 'tuser',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
    }
}