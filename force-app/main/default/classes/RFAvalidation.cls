public with sharing class RFAvalidation {
    @AuraEnabled
    public static Request_For_Agreement__c getAllRelatedParcels(Id RFAId){
        try {
            List<Request_For_Agreement__c> rfaList = [SELECT Grantee_Name__c, Lease_Version_Document_Name__c, Name, Spouse_Information__c, Land_Owner_Information__c, 
            Title_Clear__c, Title_Issues_Comments__c, Agreement_Type__c, Signing_Authority_Documents_Obtained__c, Comments_for_Title_Doc_Prep__c, 
            Acreage_Being_Signed__c, Request_Type__c, Project_Name__r.Name,
            (SELECT Id, Parcel_ID_Local__c, Deed_Acres__c, GIS_Acres__c, County__c, State__c, Request_for_Amendment__c, Request_for_Amendment_Name__c FROM Agreement_Parcels__r)
            FROM Request_for_Agreement__c
            WHERE Id = :RFAId];
            return rfaList[0];
        } catch (Exception ex) {throw new AuraHandledException('Error retrieving RFA and Parcels: ' + ex.getMessage() + ' --- ' + ex.getStackTraceString());}
    }
    
    @AuraEnabled
    public static Request_For_Amendment__c getAmendment(Id RFAAmendId){
       
            List<Request_For_Amendment__c> rfaAmendList = [SELECT Id, Lease_Version_Document_Name__c, 
            Name, Spouse_Information__c, Land_Owner_Information__c, 
            Agreement_Type__c,Title_Clear__c, Project__c, Project__r.Name, Title_Issues_Comments__c, Request_for_Agreement__c,
            (SELECT Id, Parcel_ID_Local__c, Deed_Acres__c, GIS_Acres__c, County__c, State__c, Request_for_Amendment__c, Request_for_Amendment_Name__c FROM Agreement_Parcels__r)
            FROM Request_For_Amendment__c
            WHERE Id = :RFAAmendId];
            return rfaAmendList[0];
       
    }
}