@istest
private class HTTPcreateLandOwnerTest {
    @istest
    static void HTTPcreateLandOwnerTest() {

        Project__c proj = new Project__c(Name = 'DCprojFour');
insert proj;

Account acc = new Account(Name = 'DCaccountFour', RecordTypeId ='0124W000000y85qQAA', Project_Required__c=proj.id);
insert acc;

Contact recip = new Contact(FirstName = 'dc',LastName = 'test',RecordTypeId='0124W000001AmGOQA0', Vendor_ID__c='777717');
insert recip;

Project_Team__c ProjTeam = new Project_Team__c(Project__c=proj.id, Role__c='External Title Specialist', 
User__c ='0054W00000EeireQAB');
insert ProjTeam;

Request_for_Agreement__c rfa = new Request_for_Agreement__c(Name = 'DCrfaFour', Account__c = acc.id,
Project_Name__c = proj.id, Agreement_Type__c ='Wind Energy Lease and Easement Agreement');
insert rfa;

Parcel__c parcelrec  = new Parcel__c (Name = '0999x', Account__c = acc.id, Parcel_ID_Local__c = 'ID0999x', Acres_Deed__c =13,Acres_GIS__c=17,State_Province__c='CO',County__c='Springfield');
insert parcelrec;

Agreement_Parcel__c agreeParcel= new Agreement_Parcel__c (Parcel__c = parcelrec.id, Request_for_Agreement__c=rfa.id);
insert agreeParcel;

Payment_Calculation__c payCalc = new Payment_Calculation__c ( Project__c = proj.id,  Account__c=acc.id, Request_for_Agreement__c=rfa.id);
insert payCalc;

Payment_Party__c paymentParty = new Payment_Party__c(Request_for_Agreement__c= rfa.id, Individual_Involved__c=recip.id);
insert paymentParty;

Land_Owner_Payment__c LOP = new Land_Owner_Payment__c (	Payment_Calculation__c = payCalc.id, Project__c=proj.id, TEMPInvoiceNumber__c ='xxx', 
                                                       Payment_Party__c=paymentParty.id);
insert LOP;
        List<String> myStrings = new List<String>{LOP.id};
        
Test.setMock(HttpCalloutMock.class, new HTTPCalloutServiceMock());
Test.startTest();
      
HTTPcreateLandOwner.HTTPcreateLandOwner(myStrings);
Test.stopTest();


    }
}