@isTest
public with sharing class ContractExpirationExtensionBatchTest {
    // // Picklist entries
    // static List<String> ple = new List<String>();

    // @TestSetup
    // static void makeData(){
    //     // Get valid picklist values
    //     String objectName = 'Request_for_Agreement__c';
    //     String fieldName = 'Agreement_Type__c';

    //     // Get the Schema for the object and field
    //     Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
    //     Schema.DescribeSObjectResult objResult = objectType.getDescribe();
    //     Schema.DescribeFieldResult fieldResult = objResult.fields.getMap().get(fieldName).getDescribe();

    //     // Get the picklist values
    //     List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();

    //     // Loop through the picklist values and check if they are active
    //     for (Schema.PicklistEntry entry : picklistValues) {
    //         if (entry.isActive()) {
    //             ple.add(entry.getValue());
    //         }
    //     }
    // }

    @isTest 
    static void ContractExpirationRun() {
        // Step 1: Setup Test Data
        Account a = new Account(Name = 'Test Account');
        insert a;

        Contact c = new Contact(
            FirstName='Test',
            LastName='Contact',
            Email='testcontact'+UserInfo.getOrganizationId()+'@mailinator.com',
            AccountId=a.Id
        );
        insert c;

        Project__c project = new Project__c(
            Project_Technology_Type__c = 'Solar'
        );
        insert project;

        Request_for_Agreement__c request = new Request_for_Agreement__c(
            Development_Term_Length__c = '2',  // Initial term length of 4 years
            Development_Term_Extension_1__c = '2', // 2 years
            Development_Term_Extension_2__c = '2',
            Development_Term_Extension_3__c = '2',
            Development_Term_Extension_4__c = '1',
            Development_Term_Extension_5__c = '2',
            Number_Of_Development_Term_Extensions__c = '5',
            Project_Name__c = project.Id,
            Account__c = a.Id,
            Agreement_Type__c = 'Access Agreement',
            Status__c = 'Agreement Available'
        );
        insert request;

        Date sDate = Date.today();

        Contract contract = new Contract(
            AccountId = a.Id,
            ContractTerm = 12,
            Request_for_Agreement__c = request.Id,
            StartDate = Date.today(),
            Last_Used_Term_Extension__c = 1,
            Lease_Expiration_Extension__c = System.today().addYears(-4)
        );
        insert contract;
        

        // Step 2: Run the Batch Job
        Test.startTest();
            ContractExpirationExtensionBatchClass gdfc = new ContractExpirationExtensionBatchClass();
            gdfc.testDate = contract.Lease_Expiration_Extension__c.addDays(10); // Set a test date that is after the Lease Expiration
            Database.executeBatch(gdfc, 200);
        Test.stopTest();

        // Step 3: Verify the results
        List<Contract> contracts = [SELECT Id, Lease_Expiration_Extension__c, Last_Used_Term_Extension__c FROM Contract WHERE Id = :contract.Id];
        // Adjust the expected date after applying the extension logic
        Date newExtensionDate = sDate.addYears(Integer.valueOf(request.Development_Term_Extension_4__c));
        System.assertEquals(newExtensionDate, contracts[0].Lease_Expiration_Extension__c, 'Lease Expiration should be extended by ' + newExtensionDate + ' years');
        System.assertEquals(4, contracts[0].Last_Used_Term_Extension__c, 'The Last Used Term Extension should be 4');
    }

    @isTest 
    static void ContractExpirationRunWithDecimalExtensions() {
        // Step 1: Setup Test Data
        Account a = new Account(Name = 'Test Account');
        insert a;
    
        Contact c = new Contact(
            FirstName='Test',
            LastName='Contact',
            Email='testcontact'+UserInfo.getOrganizationId()+'@mailinator.com',
            AccountId=a.Id
        );
        insert c;
    
        Project__c project = new Project__c(
            Project_Technology_Type__c = 'Solar'
        );
        insert project;
    
        Request_for_Agreement__c request = new Request_for_Agreement__c(
            Development_Term_Length__c = '4',  // Initial term length of 4 years
            Development_Term_Extension_1__c = '1',  // 1 year
            Development_Term_Extension_2__c = '0.5', // 6 months
            Development_Term_Extension_3__c = '2',  // 2 years
            Development_Term_Extension_4__c = '2',  // 2 years
            Number_Of_Development_Term_Extensions__c = '3',
            Project_Name__c = project.Id,
            Account__c = a.Id,
            Agreement_Type__c = 'Access Agreement',
            Status__c = 'Agreement Available'
        );
        insert request;

        Date sDate = Date.newInstance(2024, 5, 31);
        Date expirationDate = sDate.addYears(Integer.valueOf(request.Development_Term_Length__c)); // 4 years from start date
        Contract contract = new Contract(
            AccountId = a.Id,
            ContractTerm = 12,
            Request_for_Agreement__c = request.Id,
            Lease_Expiration_Extension__c = Date.today().addMonths(-5),
            StartDate = sDate,
            Last_Used_Term_Extension__c = 1
        );
        insert contract;
    
        // Step 2: Run the Batch Job
        Test.startTest();
        ContractExpirationExtensionBatchClass gdfc = new ContractExpirationExtensionBatchClass();
        gdfc.testDate = Date.today().addMonths(6); // Set a test date that is after the Lease Expiration
        Database.executeBatch(gdfc, 15);
        Test.stopTest();
    
        // Step 3: Verify the results
        List<Contract> contracts = [SELECT Id, Lease_Expiration_Extension__c, Last_Used_Term_Extension__c FROM Contract WHERE Id = :contract.Id];
        
        Date newExtensionDate = contract.Lease_Expiration_Extension__c.addMonths(6);
        System.assertEquals(newExtensionDate, contracts[0].Lease_Expiration_Extension__c);
        System.assertEquals(2, contracts[0].Last_Used_Term_Extension__c, 'The Last Used Term Extension should be 2');
    }
    
    // Test that the final term extension value is never used when multiple extensions
    @isTest
    static void testNotUsesFinalExtensionWithMultiple() {
        // Step 1: Setup Test Data
        Account a = new Account(Name = 'Test Account');
        insert a;

        Contact c = new Contact(
            FirstName='Test',
            LastName='Contact',
            Email='testcontact'+UserInfo.getOrganizationId()+'@mailinator.com',
            AccountId=a.Id
        );
        insert c;

        Project__c project = new Project__c(
            Project_Technology_Type__c = 'Solar'
        );
        insert project;

        Request_for_Agreement__c request = new Request_for_Agreement__c(
            Development_Term_Length__c = '4',  // Initial term length of 4 years
            Development_Term_Extension_1__c = '2', // 2 years
            Development_Term_Extension_2__c = '2',
            Development_Term_Extension_3__c = '2',
            Development_Term_Extension_4__c = '2',
            Development_Term_Extension_5__c = '2',
            Number_Of_Development_Term_Extensions__c = '5',
            Project_Name__c = project.Id,
            Account__c = a.Id,
            Agreement_Type__c = 'Access Agreement',
            Status__c = 'Agreement Available'
        );
        insert request;

        Date sDate = Date.today().addDays(5);
        // Initial expiry is 4 Years
        Integer initialExpiryDate = 4; // Add 4 years to Extension
        Contract contract = new Contract(
            AccountId = a.Id,
            ContractTerm = 12,
            Request_for_Agreement__c = request.Id,
            StartDate = sDate,
            Last_Used_Term_Extension__c = 4
        );
        insert contract;

        // Step 2: Run the Batch Job
        Test.startTest();
            ContractExpirationExtensionBatchClass gdfc = new ContractExpirationExtensionBatchClass();
            contract.Lease_Expiration_Extension__c = System.today().addDays(-5);
            update contract;
            gdfc.testDate = contract.Lease_Expiration_Extension__c.addDays(10); // Set a test date that is after the Lease Expiration
            Database.executeBatch(gdfc, 200);
        Test.stopTest();

        // Step 3: Verify the results
        List<Contract> contracts = [SELECT Id, Lease_Expiration_Extension__c, Last_Used_Term_Extension__c FROM Contract WHERE Id = :contract.Id];

        System.assertEquals(contract.Lease_Expiration_Extension__c, contracts[0].Lease_Expiration_Extension__c, 'Lease Expiration should not be extended, as it reached the final term extension');
        System.assertEquals(4, contracts[0].Last_Used_Term_Extension__c, 'The Last Used Term Extension should be 4');
    }

    @isTest
    static void testNotUsesFinalExtensionWithSingleValue() {
        // Step 1: Setup Test Data
        Account a = new Account(Name = 'Test Account');
        insert a;

        Contact c = new Contact(
            FirstName='Test',
            LastName='Contact',
            Email='testcontact'+UserInfo.getOrganizationId()+'@mailinator.com',
            AccountId=a.Id
        );
        insert c;

        Project__c project = new Project__c(
            Project_Technology_Type__c = 'Solar'
        );
        insert project;

        Request_for_Agreement__c request = new Request_for_Agreement__c(
            Development_Term_Length__c = '4',  // Initial term length of 4 years
            Development_Term_Extension_1__c = '2',
            Project_Name__c = project.Id,
            Account__c = a.Id,
            Agreement_Type__c = 'Access Agreement',
            Status__c = 'Agreement Available'
        );
        insert request;

        Date sDate = Date.today().addDays(5);
        // Initial expiry is 4 Years
        Integer initialExpiryDate = 4; // Add 4 years to Extension
        Contract contract = new Contract(
            AccountId = a.Id,
            ContractTerm = 12,
            Request_for_Agreement__c = request.Id,
            StartDate = sDate
        );
        insert contract;

        // Step 2: Run the Batch Job
        Test.startTest();
            ContractExpirationExtensionBatchClass gdfc = new ContractExpirationExtensionBatchClass();
            contract.Lease_Expiration_Extension__c = System.today().addDays(-5);
            update contract;
            gdfc.testDate = contract.Lease_Expiration_Extension__c.addDays(10); // Set a test date that is after the Lease Expiration
            Database.executeBatch(gdfc, 200);
        Test.stopTest();

        // Step 3: Verify the results
        List<Contract> contracts = [SELECT Id, Lease_Expiration_Extension__c, Last_Used_Term_Extension__c FROM Contract WHERE Id = :contract.Id];

        System.assertEquals(contract.Lease_Expiration_Extension__c, contracts[0].Lease_Expiration_Extension__c, 'Lease Expiration should not be extended, as it reached the final term extension');
        System.assertEquals(null, contracts[0].Last_Used_Term_Extension__c, 'The Last Used Term Extension should be null');
    }
}