/**
 * @description       : 
 * @author            : NuAge - JP
 * @group             : 
 * @last modified on  : 06-24-2024
 * @last modified by  : NuAge - JP
**/
@isTest
public with sharing class ContractExpirationExtensionBatchTest {
    @isTest static void ContractExpirationRun() {
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

        // Group g = new Group(Type='Queue', DeveloperName='External_Title_Specialist', Name = 'External Title Specialist'); 
        // insert g;

        Request_for_Agreement__c request = new Request_for_Agreement__c(
            Development_Term_Length__c = '1',
            Development_Term_Extension_1__c = '2',
            Development_Term_Extension_2__c = '2',
            Development_Term_Extension_3__c = '2',
            Development_Term_Extension_4__c = '2',
            Development_Term_Extension_5__c = '2',
            Number_Of_Development_Term_Extensions__c = '5',
            Project_Name__c = project.Id,
            Account__c = a.Id,
            Agreement_Type__c = 'Irrigation',
            Status__c = 'Vesting Deeds Complete'
        );
        insert request;

        Date sDate = Date.newInstance(2024, 5, 31);
        Date expirationDate = Date.newInstance(2025, 5, 31);
        Contract con = new Contract(
            AccountId = a.Id,
            // StartDate = date.today(),
            ContractTerm = 12,
            Request_for_Agreement__c = request.Id,
            Lease_Expiration_Extension__c = expirationDate,
            StartDate = sDate
        );
        insert con;
        test.startTest();
            ContractExpirationExtensionBatchClass gdfc = new ContractExpirationExtensionBatchClass();
            gdfc.testDate = date.newInstance(2025, 6, 1);
            Database.executeBatch(gdfc, 15);
        test.stopTest();

        List<Contract> contract = [SELECT Id, Lease_Expiration_Extension__c FROM Contract];
        Date leaseDate = date.newInstance(2028, 5, 31);
        system.assertEquals(leaseDate, contract[0].Lease_Expiration_Extension__c);
    }

    @isTest static void ContractExpirationRun2() {
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

        // Group g = new Group(Type='Queue', DeveloperName='External_Title_Specialist', Name = 'External Title Specialist'); 
        // insert g;

        Request_for_Agreement__c request = new Request_for_Agreement__c(
            Development_Term_Length__c = '1',
            Development_Term_Extension_1__c = '2',
            Development_Term_Extension_2__c = '2',
            Development_Term_Extension_3__c = '2',
            Development_Term_Extension_4__c = '2',
            Development_Term_Extension_5__c = '2',
            Number_Of_Development_Term_Extensions__c = '5',
            Project_Name__c = project.Id,
            Account__c = a.Id,
            Agreement_Type__c = 'Irrigation',
            Status__c = 'Vesting Deeds Complete'
        );
        insert request;

        Date sDate = Date.newInstance(2024, 5, 31);
        Date expirationDate = Date.newInstance(2028, 5, 31);
        Contract con = new Contract(
            AccountId = a.Id,
            // StartDate = date.today(),
            ContractTerm = 12,
            Request_for_Agreement__c = request.Id,
            Lease_Expiration_Extension__c = expirationDate,
            StartDate = sDate
        );
        insert con;
        test.startTest();
            ContractExpirationExtensionBatchClass gdfc = new ContractExpirationExtensionBatchClass();
            gdfc.testDate = date.newInstance(2028, 6, 1);
            Database.executeBatch(gdfc, 15);
        test.stopTest();

        List<Contract> contract = [SELECT Id, Lease_Expiration_Extension__c FROM Contract];
        Date leaseDate = date.newInstance(2030, 5, 31);
        system.assertEquals(leaseDate, contract[0].Lease_Expiration_Extension__c);
    }


    @isTest static void ContractExpirationRun_Scheduler() {
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

        // Group g = new Group(Type='Queue', DeveloperName='External_Title_Specialist', Name = 'External Title Specialist'); 
        // insert g;

        Request_for_Agreement__c request = new Request_for_Agreement__c(
            Development_Term_Length__c = '1',
            Development_Term_Extension_1__c = '2',
            Development_Term_Extension_2__c = '2',
            Development_Term_Extension_3__c = '2',
            Development_Term_Extension_4__c = '2',
            Development_Term_Extension_5__c = '2',
            Project_Name__c = project.Id,
            Account__c = a.Id,
            Agreement_Type__c = 'Irrigation',
            Status__c = 'Vesting Deeds Complete'
        );
        insert request;

        Date sDate = Date.newInstance(2024, 5, 31);
        Date expirationDate = Date.newInstance(2028, 5, 31);
        Contract con = new Contract(
            AccountId = a.Id,
            // StartDate = date.today(),
            ContractTerm = 12,
            Request_for_Agreement__c = request.Id,
            Lease_Expiration_Extension__c = expirationDate,
            StartDate = sDate
        );
        insert con;
        test.startTest();
            String sch1 = '0 0 0 * * ? *';
            ContractExpirationExtensionScheduler ups = new ContractExpirationExtensionScheduler();
            system.schedule('Contract Status Extension', sch1, ups);
        test.stopTest();

        // List<Contract> contract = [SELECT Id, Lease_Expiration_Extension__c FROM Contract];
        // Date leaseDate = date.newInstance(2030, 5, 31);
        // system.assertEquals(leaseDate, contract[0].Lease_Expiration_Extension__c);
    }
}