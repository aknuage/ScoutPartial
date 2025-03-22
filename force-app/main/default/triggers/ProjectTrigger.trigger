trigger ProjectTrigger on Project__c (
    before insert,
    before update,
    after insert,
    after update,
    before delete,
    after delete,
    after undelete)
{
    new ProjectTriggerHandler().run();
}