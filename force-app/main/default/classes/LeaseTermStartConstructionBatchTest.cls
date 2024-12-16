/**
 * Tests LeaseTermStartConstructionBatch and TermTriggerHandler.
 */
@isTest
public class LeaseTermStartConstructionBatchTest {
    
    @testSetup
    static void setupTestData() {

        Account a = new Account(Name = 'NuAge Test');
        insert a;

        Id landOwnerConId = [SELECT Id FROM RecordType WHERE RecordType.Name = 'Land Owner Contact' LIMIT 1].Id;
        Contact con = new Contact(FirstName = 'Anthony', LastName = 'NuAge', RecordTypeId = landOwnerConId);
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

            // Create test data for Term__c
            List<Term__c> terms = new List<Term__c>();
            for (Integer i = 0; i < 3; i++) {
                terms.add(new Term__c(
                    Name = 'Test Term ' + i,
                    Start_of_Construction_Date__c = Date.today().addDays(-5),
                    Project__c = projects[i].Id
                ));
            }
            insert terms;

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
        // Query termProjectIds
        Set<Id> termProjectIds = new Set<Id>();
        for (Term__c term : [SELECT Project__c FROM Term__c WHERE Start_of_Construction_Date__c != null]) {
            termProjectIds.add(term.Project__c);
        }

        // Run the batch
        Test.startTest();
        Database.executeBatch(new LeaseTermStartConstructionBatch(termProjectIds), 30);
        Test.stopTest();

        // Assert that payments due after the start of construction are terminated
        List<Land_Owner_Payment__c> payments = [SELECT Id, Status__c, Due_Date_to_override__c FROM Land_Owner_Payment__c];
        for (Land_Owner_Payment__c payment : payments) {
            if (payment.Due_Date_to_override__c != null && payment.Due_Date_to_override__c > Date.today().addDays(-5)) {
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
        List<Term__c> termsToUpdate = [SELECT Id, Start_of_Construction_Trigger__c, Start_of_Construction_Date__c
                                        FROM Term__c];
        for (Term__c term : termsToUpdate) {
            term.Start_of_Construction_Trigger__c = true;
            term.Start_of_Construction_Date__c = Date.today().addDays(-5);
        }
    
        Test.startTest();
            update termsToUpdate;
        Test.stopTest();
    
        // Assert batch job execution
        // System.assertEquals(1, Limits.getJobs(), 'Batch job should have been queued.');
    
        // Assert payment status updates
        List<Land_Owner_Payment__c> payments = [SELECT Id, Status__c, Due_Date_to_override__c FROM Land_Owner_Payment__c];
        for (Land_Owner_Payment__c payment : payments) {
            if (payment.Due_Date_to_override__c != null && payment.Due_Date_to_override__c > Date.today().addDays(-5)) {
                System.assertEquals('Terminated', payment.Status__c, 'Payment should be terminated');
            } else {
                System.assertNotEquals('Terminated', payment.Status__c, 'Payment should not be terminated');
            }
        }
    }
    
    // Test with a Term that has at least 200 future payments. Could expand this by having 30 Terms updating at once
    // with 200 future payments each.
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
        Term__c newTerm = new Term__c(
            Name = 'Nuage Term Test',
            Start_of_Construction_Trigger__c = false,
            Start_of_Construction_Date__c = Date.today().addDays(-5),
            Project__c = project.Id
        );
        insert newTerm;

        Test.startTest();
            insert payments;
            for (Land_Owner_Payment__c l : payments) {
                paymentIds.add(l.Id);
            }
            // Update Term to trigger Batch class
            newTerm.Start_of_Construction_Trigger__c = true;
            newTerm.Start_of_Construction_Date__c = Date.today().addDays(-10);
            update newTerm;
        Test.stopTest();
        
        // All Payments should be terminated, because they are later than the Term's Construction Start Date
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
