/**
 * @description       : 
 * @author            : NuAge - JP
 * @group             : 
 * @last modified on  : 09-03-2024
 * @last modified by  : NuAge - JP
**/
trigger ProjectTeamTrigger on Project_Team__c (
    before insert,
    before update,
    before delete,
    after insert, 
    after update,
    after delete,
    after undelete) {
            if(Trigger.isBefore){ 
                /*
                if(Trigger.isInsert){
    
                }
                if(Trigger.isUpdate){
                    
                }
                else if(Trigger.isDelete){
                    
                }
                */
            }
            else{
                if(Trigger.isInsert){ProjectTeamController.projectTeam_insert(Trigger.new); }
                else if(Trigger.isUpdate){ ProjectTeamController.projectTeam_update(Trigger.new, Trigger.oldMap); }
                else if(Trigger.isDelete){ProjectTeamController.projectTeam_delete(Trigger.old);}
                /*
                else if(Trigger.isUndelete){
                    
                }
                */
            }
}