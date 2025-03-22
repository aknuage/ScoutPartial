/**
 * @author: akelly @ NuAge : December 12, 20224
 */
public with sharing class TermTriggerHandler extends TriggerHandler {
    

    public override void afterUpdate()
    {
        Set<Id> constructionTermProjectIds = new Set<Id>();

        List<Term__c> newList = (List<Term__c>) Trigger.new;
        Map<Id,Term__c> oldMap = (Map<Id,Term__c>) Trigger.oldMap;

        for (Term__c t : newList)
        {
            System.debug('term in new list: ' + t.Start_of_Construction_Trigger__c);
            // Check if Start of Construction has occurred
            if (t.Start_of_Construction_Trigger__c == true && oldMap.get(t.Id).Start_of_Construction_Trigger__c == false)
            {
                if (t.Start_of_Construction_Date__c != null) // Check that Start Date not null
                {
                    constructionTermProjectIds.add(t.Project__c);
                }
            }
        }
        // AK - pass terms IDs to batch class to terminate past Land Owner Payments
        if (!constructionTermProjectIds.isEmpty()) 
        {
            Database.ExecuteBatch(new LeaseTermStartConstructionBatch(constructionTermProjectIds), 30);
        }
    }

}