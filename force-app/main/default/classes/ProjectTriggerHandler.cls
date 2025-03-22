public with sharing class ProjectTriggerHandler extends TriggerHandler {
    
    public override void afterUpdate()
    {
        Set<Id> constructionStartIds = new Set<Id>();

        List<Project__c> newList = (List<Project__c>) Trigger.new;
        Map<Id,Project__c> oldMap = (Map<Id,Project__c>) Trigger.oldMap;

        for (Project__c p : newList)
        {
            System.debug('term in new list: ' + p.Construction_Start_Date__c);
            Boolean startDateChanged = p.Construction_Start_Date__c != null && oldMap.get(p.Id).Construction_Start_Date__c != null && oldMap.get(p.Id).Construction_Start_Date__c != p.Construction_Start_Date__c;
            
            // AK @ NuAge Experts: Kick off Batch process if Construction Date on Project has changed
            if ((p.Construction_Start_Date__c != null && oldMap.get(p.Id).Construction_Start_Date__c == null) || startDateChanged)
            {
                constructionStartIds.add(p.Id);
            }
        }
        // AK @ NuAge - pass Project IDs to batch class to terminate past Land Owner Payments
        if (!constructionStartIds.isEmpty()) 
        {
            Database.ExecuteBatch(new LeaseTermStartConstructionBatch(constructionStartIds), 30);
        }
    }
}