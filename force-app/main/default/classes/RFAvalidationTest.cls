/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class RFAvalidationTest {

    @isTest
    static void myUnitTest() {
        // TO DO: implement unit test
       
Project__c proj = new Project__c(Name = 'DCprojSeven');
insert proj;

Account acc = new Account(Name = 'DCaccountSeven', RecordTypeId ='0124W000000y85qQAA', Project_Required__c=proj.id);
insert acc;

Project_Team__c ProjTeam = new Project_Team__c(Project__c=proj.id, Role__c='External Title Specialist', 
User__c ='0054W00000EeireQAB');
insert ProjTeam;

Request_for_Agreement__c rfa = new Request_for_Agreement__c(Name = 'DCrfaSeven', Account__c = acc.id,
Project_Name__c = proj.id, Agreement_Type__c ='Wind Energy Lease and Easement Agreement');
insert rfa;

Parcel__c parcelrec  = new Parcel__c (Name = '0999x', Account__c = acc.id, Parcel_ID_Local__c = 'ID0999x', Acres_Deed__c =13,Acres_GIS__c=17,State_Province__c='CO',County__c='Springfield');
insert parcelrec;

Agreement_Parcel__c agreeParcel= new Agreement_Parcel__c (Parcel__c = parcelrec.id, Request_for_Agreement__c=rfa.id);
insert agreeParcel;

Test.startTest();
RFAvalidation.getAllRelatedParcels(rfa.id);
Test.stopTest();

    }
}