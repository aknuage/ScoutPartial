/**
 * @description: Tests LeaseTermStartConstructionBatch and ProjectTriggerHandler.
 * @author: AKelly @ NuAge Experts : December 2024
 */
@isTest
public class LeaseTermStartConstructionBatchTest {
    
    @testSetup
    static void setupTestData() {

        Account a = new Account(Name = 'NuAge Test');
        insert a;

        // Id landOwnerConId = [SELECT Id FROM RecordType WHERE RecordType.Name = 'Land Owner Contact' LIMIT 1].Id;
        Contact con = new Contact(FirstName = 'Anthony', LastName = 'NuAge'
                                  // RecordTypeId = landOwnerConId
                                 );
        insert con;

        // Create System Admin User to override Read/Write limits on Terms
        String uniqueUserName = 'sysadmin' + DateTime.now().getTime() + '@testorg.com';
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User admin = new User(
            Alias = 'standt',
            Email = 'standarduser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = uniqueUserName
        );
        insert admin;

        System.runAs(admin) {
            // Create test data for Project__c
            List<Project__c> projects = new List<Project__c>();
            for (Integer i = 0; i < 3; i++) {
                projects.add(new Project__c(Name = 'Test Project ' + i));
            }
            insert projects;

            // Create related data for formula fields
            List<Payment_Calculation__c> paymentCalculations = new List<Payment_Calculation__c>();
            for (Integer i = 0; i < 6; i++) {
                paymentCalculations.add(new Payment_Calculation__c(
                    Account__c = a.Id,
                    Payment_Type__c = (Math.mod(i, 2) == 0) ? 'Amendment Payment' : 'Development Payment',
                    Due_Date_Calculation__c = Date.today().addDays(-10 + i) // Adjusted for testing formula logic
                ));
            }
            insert paymentCalculations;
            Payment_Party__c party = new Payment_Party__c(Individual_Involved__c = con.Id, Active__c = true, Payment_Method__c = 'Direct Deposit');
            insert party;

            // Create test data for Land_Owner_Payment__c
            List<Land_Owner_Payment__c> payments = new List<Land_Owner_Payment__c>();
            for (Integer i = 0; i < 6; i++) {
                Land_Owner_Payment__c payment = new Land_Owner_Payment__c(
                    Status__c = 'Pending',
                    Payment_Party__c = party.Id,
                    Payment_Calculation__c = paymentCalculations[Math.mod(i, 3)].Id,
                    Due_Date_to_override__c = (Math.mod(i, 2) == 0) ? null : Date.today().addDays(i), // Alternate override dates
                    Project__c = projects[i / 2].Id
                );
                payments.add(payment);
            }
            insert payments;
        }
    }

    @isTest
    static void testBatchExecution() {
        Map<Id, Project__c> projectsForUpdate = new Map<Id, Project__c>();
        List<Project__c> existingProjects = [SELECT Id, Construction_Start_Date__c FROM Project__c];
        for (Project__c p : existingProjects) {
            p.Construction_Start_Date__c = Date.today().addMonths(-5);
            projectsForUpdate.put(p.Id, p);
        }
        // Run the batch
        Test.startTest();
        update projectsForUpdate.values();
        Database.executeBatch(new LeaseTermStartConstructionBatch(projectsForUpdate.keySet()), 30);
        Test.stopTest();

        // Assert that payments due after the start of construction are terminated
        List<Land_Owner_Payment__c> payments = [SELECT Id, Status__c, Project__r.Construction_Start_Date__c, Due_Date__c FROM Land_Owner_Payment__c];
        for (Land_Owner_Payment__c payment : payments) {
            if (payment.Due_Date__c > payment.Project__r.Construction_Start_Date__c) {
                System.assertEquals('Terminated', payment.Status__c, 'Payment should be terminated');
            } else {
                System.assertNotEquals('Terminated', payment.Status__c, 'Payment should not be terminated');
            }
        }
    }

    // Test that Batch fires from update of Terms
    @isTest
    static void testBatchExecutesOnTermUpdate() {
    
        // Update Terms to trigger the batch
        List<Project__c> projectsToUpdate = [SELECT Id, Construction_Start_Date__c FROM Project__c];
        for (Project__c p : projectsToUpdate) {
            p.Construction_Start_Date__c = Date.today().addMonths(-5);
        }
    
        Test.startTest();
            update projectsToUpdate;
        Test.stopTest();
        
        // Assert payment status updates
        List<Land_Owner_Payment__c> payments = [SELECT Id, Status__c, Due_Date__c, Project__r.Construction_Start_Date__c FROM Land_Owner_Payment__c];
        for (Land_Owner_Payment__c payment : payments) {
            if (payment.Due_Date__c > payment.Project__r.Construction_Start_Date__c) {
                System.assertEquals('Terminated', payment.Status__c, 'Payment should be terminated');
            } else {
                System.assertNotEquals('Terminated', payment.Status__c, 'Payment should not be terminated');
            }
        }
    }
    

    @isTest
    static void testBatchExecutionUpdateBulk()
    {
        Set<Id> paymentIds = new Set<Id>();
        Project__c project = [SELECT Id FROM Project__c LIMIT 1];
        Payment_Party__c party = [SELECT Id FROM Payment_Party__c LIMIT 1];
        Payment_Calculation__c paymentCalculation = [SELECT Id FROM Payment_Calculation__c LIMIT 1];
        // Create test data for Land_Owner_Payment__c
        List<Land_Owner_Payment__c> payments = new List<Land_Owner_Payment__c>();
        for (Integer i = 0; i < 200; i++) {
            Land_Owner_Payment__c payment = new Land_Owner_Payment__c(
                Status__c = 'Pending',
                Payment_Party__c = party.Id,
                Payment_Calculation__c = paymentCalculation.Id,
                Due_Date_to_override__c = Date.today().addDays(i),
                Project__c = project.Id
            );
            payments.add(payment);
        }


        Test.startTest();
            insert payments;
            for (Land_Owner_Payment__c l : payments) {
                paymentIds.add(l.Id);
            }
            project.Construction_Start_Date__c = Date.today().addMonths(-6);
            update project;
        Test.stopTest();

        for (Land_Owner_Payment__c lop : [SELECT Status__c FROM Land_Owner_Payment__c WHERE ID IN :paymentIds])
        {
            System.assertEquals('Terminated', lop.Status__c);
        }
    }


    @isTest
    static void testEmptyBatchExecution() {
        // Pass an empty set of termProjectIds
        Test.startTest();
        Database.executeBatch(new LeaseTermStartConstructionBatch(new Set<Id>()), 1);
        Test.stopTest();

        // Assert no changes were made
        Integer terminatedPayments = [SELECT COUNT() FROM Land_Owner_Payment__c WHERE Status__c = 'Terminated'];
        System.assertEquals(0, terminatedPayments, 'No payments should have been terminated');
    }
}