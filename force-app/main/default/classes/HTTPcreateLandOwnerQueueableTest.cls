@istest
private class HTTPcreateLandOwnerQueueableTest {
    // Test using CreateLandOwnerInvocable method to query for LOP, then pass it to the Queuable and confirm transactions succeeded separately
    @istest
    static void testSeparationOfTransactions() {

        Project__c proj = new Project__c(Name = 'DCprojFour', Accounting_Project_Code__c = '100200');
        insert proj;

        Account acc = new Account(Name = 'DCaccountFour', Project_Required__c = proj.id);
        insert acc;

        /*
        Account acc = new Account(Name = 'DCaccountFour', RecordTypeId ='0124W000000y85qQAA', Project_Required__c=proj.id);
        insert acc;
        */

        Contact recip = new Contact(FirstName = 'dc', LastName = 'test', RecordTypeId = '0124W000001AmGOQA0', Vendor_ID__c = '777717');
        insert recip;

        Profile ScoutTeam = [SELECT Id FROM Profile where name = 'Scout Team'
            Limit 1
        ];


        USER testUser = new User(FirstName = 'Fred', LastName = 'flintstone', profileId = ScoutTeam.Id, alias = 'fflint', email = 'test@example.com',
            username = 'testasdf@example.com', TimeZoneSidKey = 'GMT', LanguageLocaleKey = 'en_US', EmailEncodingKey = 'UTF-8',
            LocaleSidKey = 'en_US');
        insert testUser;


        Project_Team__c ProjTeam = new Project_Team__c(Project__c = proj.id, Role__c = 'External Title Specialist',
            User__c = '0054W00000EeireQAB');
        insert ProjTeam;

        Request_for_Agreement__c rfa = new Request_for_Agreement__c(Name = 'DCrfaFour', Account__c = acc.id,
            Project_Name__c = proj.id, Agreement_Type__c = 'Wind Energy Lease and Easement Agreement');
        insert rfa;

        Parcel__c parcelrec = new Parcel__c(Name = '0999x', Account__c = acc.id, Parcel_ID_Local__c = 'ID0999x', Acres_Deed__c = 13, Acres_GIS__c = 17, State_Province__c = 'CO', County__c = 'Springfield');
        insert parcelrec;

        Agreement_Parcel__c agreeParcel = new Agreement_Parcel__c(Parcel__c = parcelrec.id, Request_for_Agreement__c = rfa.id);
        insert agreeParcel;

        Payment_Calculation__c payCalc = new Payment_Calculation__c(Project__c = proj.id, Account__c = acc.id, Request_for_Agreement__c = rfa.id);
        insert payCalc;

        Payment_Party__c paymentParty = new Payment_Party__c(Request_for_Agreement__c = rfa.id, Individual_Involved__c = recip.id);
        insert paymentParty;

        Land_Owner_Payment__c LOP = new Land_Owner_Payment__c(Payment_Calculation__c = payCalc.id,
            Project__c = proj.id, TEMPInvoiceNumber__c = 'xxx',
            Payment_Party__c = paymentParty.id );
        insert LOP;
        List < String > myStrings = new List < String > {
            LOP.id
        };

        Test.setMock(HttpCalloutMock.class, new HTTPCalloutServiceMock());
        Test.startTest();
            LOP.TEMPInvoiceNumber__c = '1234';
        	update LOP;
			CreateLandOwnerInvocable.GetLopAndMakeCallout(myStrings);
        Test.stopTest();
        
        Land_Owner_Payment__c  assertLOP = [SELECT OracleBusinessUnit__c,OracleInvoiceSource__c, OracleInvoiceGroup__c,InvoiceNumber__c,
        OracleCurrency__c, Actual_Payment_to_Payee__c, OracleDate__c, OracleSupplier__c,
        OracleSupplierSite__c,	OracleLegalEntity__c, OracleInvoiceType__c, 
        NotestoAccounting__c, OracleDistributionSet__c, OracleDistributionCombination__c, OracleProjectId__c, 
        OracleTaskId__c,  OracleExpenditureTypeID__c, 
        OracleOrganizationIdDisplay__c, Vendor_ID__c FROM Land_Owner_Payment__c WHERE ID=:LOP.Id limit 1];
        
        // System.debug(JSON.serializePretty(assertLOP));
       	System.assertEquals(assertLOP.InvoiceNumber__c, '1234');
    }
    
    // Test querying for the LOP record and then calling the Queueable job directly
    @istest
    static void testEnqueueJobDirectly() {

        Project__c proj = new Project__c(Name = 'DCprojFour', Accounting_Project_Code__c = '100200');
        insert proj;

        Account acc = new Account(Name = 'DCaccountFour', Project_Required__c = proj.id);
        insert acc;

        /*
        Account acc = new Account(Name = 'DCaccountFour', RecordTypeId ='0124W000000y85qQAA', Project_Required__c=proj.id);
        insert acc;
        */

        Contact recip = new Contact(FirstName = 'dc', LastName = 'test', RecordTypeId = '0124W000001AmGOQA0', Vendor_ID__c = '777717');
        insert recip;

        Profile ScoutTeam = [SELECT Id FROM Profile where name = 'Scout Team'
            Limit 1
        ];


        USER testUser = new User(FirstName = 'Fred', LastName = 'flintstone', profileId = ScoutTeam.Id, alias = 'fflint', email = 'test@example.com',
            username = 'testasdf@example.com', TimeZoneSidKey = 'GMT', LanguageLocaleKey = 'en_US', EmailEncodingKey = 'UTF-8',
            LocaleSidKey = 'en_US');
        insert testUser;


        Project_Team__c ProjTeam = new Project_Team__c(Project__c = proj.id, Role__c = 'External Title Specialist',
            User__c = '0054W00000EeireQAB');
        insert ProjTeam;

        Request_for_Agreement__c rfa = new Request_for_Agreement__c(Name = 'DCrfaFour', Account__c = acc.id,
            Project_Name__c = proj.id, Agreement_Type__c = 'Wind Energy Lease and Easement Agreement');
        insert rfa;

        Parcel__c parcelrec = new Parcel__c(Name = '0999x', Account__c = acc.id, Parcel_ID_Local__c = 'ID0999x', Acres_Deed__c = 13, Acres_GIS__c = 17, State_Province__c = 'CO', County__c = 'Springfield');
        insert parcelrec;

        Agreement_Parcel__c agreeParcel = new Agreement_Parcel__c(Parcel__c = parcelrec.id, Request_for_Agreement__c = rfa.id);
        insert agreeParcel;

        Payment_Calculation__c payCalc = new Payment_Calculation__c(Project__c = proj.id, Account__c = acc.id, Request_for_Agreement__c = rfa.id);
        insert payCalc;

        Payment_Party__c paymentParty = new Payment_Party__c(Request_for_Agreement__c = rfa.id, Individual_Involved__c = recip.id);
        insert paymentParty;

        Land_Owner_Payment__c LOP = new Land_Owner_Payment__c(Payment_Calculation__c = payCalc.id,
            Project__c = proj.id, TEMPInvoiceNumber__c = 'xxx',
            Payment_Party__c = paymentParty.id);
        insert LOP;
        
        List < String > myStrings = new List < String > {
            LOP.id
        };
            
        Land_Owner_Payment__c  LOPrecord = [SELECT OracleBusinessUnit__c,OracleInvoiceSource__c, OracleInvoiceGroup__c,InvoiceNumber__c,
        OracleCurrency__c, Actual_Payment_to_Payee__c, OracleDate__c, OracleSupplier__c,
        OracleSupplierSite__c,	OracleLegalEntity__c, OracleInvoiceType__c, 
        NotestoAccounting__c, OracleDistributionSet__c, OracleDistributionCombination__c, OracleProjectId__c, 
        OracleTaskId__c,  OracleExpenditureTypeID__c, 
        OracleOrganizationIdDisplay__c, Vendor_ID__c FROM Land_Owner_Payment__c WHERE ID=:LOP.Id limit 1];

        Test.setMock(HttpCalloutMock.class, new HTTPCalloutServiceMock());
        Test.startTest();
            LOP.TEMPInvoiceNumber__c = '1234';
        	update LOP;
        	System.enqueueJob(new HTTPcreateLandOwnerQueueable(LOPrecord));
        Test.stopTest();
        
        Land_Owner_Payment__c  assertLOP = [SELECT OracleBusinessUnit__c,OracleInvoiceSource__c, OracleInvoiceGroup__c,InvoiceNumber__c,
        OracleCurrency__c, Actual_Payment_to_Payee__c, OracleDate__c, OracleSupplier__c,
        OracleSupplierSite__c,	OracleLegalEntity__c, OracleInvoiceType__c, 
        NotestoAccounting__c, OracleDistributionSet__c, OracleDistributionCombination__c, OracleProjectId__c, 
        OracleTaskId__c,  OracleExpenditureTypeID__c, 
        OracleOrganizationIdDisplay__c, Vendor_ID__c FROM Land_Owner_Payment__c WHERE ID=:LOP.Id limit 1];
        
        // System.debug(JSON.serializePretty(assertLOP));
       	System.assertEquals(assertLOP.InvoiceNumber__c, '1234');
    }
}