/**
 * @description       : 
 * @author            : NuAge - JP
 * @group             : 
 * @last modified on  : 06-07-2024
 * @last modified by  : NuAge - JP
**/
public with sharing class ContractExpirationExtensionScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        ContractExpirationExtensionBatchClass gdfc = new ContractExpirationExtensionBatchClass();
        if(test.isRunningTest()) gdfc.testDate = date.newInstance(2028, 6, 1);
        Database.executeBatch(gdfc, 15);
    }
}

/*
    String sch1 = '0 0 0 * * ? *';
    ContractExpirationExtensionScheduler ups = new ContractExpirationExtensionScheduler();
    system.schedule('Contract Status Extension', sch1, ups);
*/