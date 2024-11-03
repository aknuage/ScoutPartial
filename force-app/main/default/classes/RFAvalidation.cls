public with sharing class RFAvalidation {
    @AuraEnabled
    public static List<Agreement_Parcel__c> getAllRelatedParcels(Id RFAId){
        return [SELECT Id, Parcel_ID_Local__c, Deed_Acres__c, GIS_Acres__c , County__c, State__c  FROM Agreement_Parcel__c WHERE Request_for_Agreement__c  = :RFAId];
    }
}