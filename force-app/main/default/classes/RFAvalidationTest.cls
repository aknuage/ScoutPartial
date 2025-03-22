@isTest
private class RFAvalidationTest {

    @isTest
    static void myUnitTest() {
        // TO DO: implement unit test
       
Project__c proj = new Project__c(Name = 'DCprojSeven');
insert proj;

Id accRecTypeId = [SELECT Id, Name, DeveloperName, SobjectType
FROM RecordType
WHERE SobjectType = 'Account' AND DeveloperName = 'Acct_RecType_LocalStakeholder' LIMIT 1].Id;

Profile ScoutTeam = [SELECT Id FROM Profile where name = 'Scout Team' Limit 1];

//TODO - Add USER RECORD - reference below
USER testUser = new User (FirstName ='Fred', LastName='flintstone', profileId=ScoutTeam.Id, alias ='fflint',email='test@example.com', 
                        username = 'testasdf@example.com', TimeZoneSidKey = 'GMT', LanguageLocaleKey = 'en_US', EmailEncodingKey = 'UTF-8',
                        LocaleSidKey = 'en_US');
insert testUser;

Account acc = new Account(Name = 'DCaccountSeven', RecordTypeId =accRecTypeId, Project_Required__c=proj.id, owner = testUser);
insert acc;

Project_Team__c ProjTeam = new Project_Team__c(Project__c=proj.id, Role__c='External Title Specialist', 
User__c =testUser.Id);
insert ProjTeam;

Project_Team__c ProjTeamExternalDocPrep = new Project_Team__c(Project__c=proj.id, Role__c='External Doc Prep', 
User__c =testUser.Id);
insert ProjTeamExternalDocPrep;

Request_for_Agreement__c rfa = new Request_for_Agreement__c(Name = 'DCrfaSeven', Account__c = acc.id,
Project_Name__c = proj.id, Agreement_Type__c ='Wind Energy Lease and Easement Agreement');
insert rfa;

Parcel__c parcelrec  = new Parcel__c (Name = '0999x', Account__c = acc.id, Parcel_ID_Local__c = 'ID0999x', Acres_Deed__c =13,Acres_GIS__c=17,State_Province__c='CO',County__c='Springfield');
insert parcelrec;

Agreement_Parcel__c agreeParcel= new Agreement_Parcel__c (Parcel__c = parcelrec.id, Request_for_Agreement__c=rfa.id);
insert agreeParcel;


Request_for_Amendment__c rfaAmendment = new Request_for_Amendment__c (Account__c = acc.id, Agreement_Type__c = 'Wind Energy Lease and Easement Agreement',
Comments_for_Doc_Prep__c='Comments',Lease_Version_Document_Name__c = 'v2',
Project__c = proj.id, Status__c = 'Request for Amendment',  Title_Clear__c = 'Yes', Title_Issues_Comments__c='Title commnet' );
insert rfaAmendment;



Test.startTest();
RFAvalidation.getAllRelatedParcels(rfa.id);


RFAvalidation.getAmendment(rfaAmendment.id);

try{
RFAvalidation.getAllRelatedParcels('asdf8877');
    } catch (Exception e) {
        System.assert(e.getMessage().contains('Invalid id'));
    }
Test.stopTest();

    }
}