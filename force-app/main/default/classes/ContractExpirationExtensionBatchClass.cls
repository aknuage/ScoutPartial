/**
 * @description       : 
 * @author            : NuAge - JP
 * @group             : 
 * @last modified on  : 06-24-2024
 * @last modified by  : NuAge - JP
**/
public with sharing class ContractExpirationExtensionBatchClass implements Database.Batchable<Contract>, Database.stateful {
    public Date testDate;
    public Iterable<Contract> start(Database.BatchableContext BC){
        Date runDate;
        if(!Test.isRunningTest()){
            // TODO: Update c.Test_Today_s_Date__c.addDays(-1) to date.today().addDays(-1)
            runDate = date.today().addDays(-1);
        } else{
            runDate = testDate.addDays(-1);
        }
        List<Contract> contracts = [SELECT Id, Lease_Expiration_Extension__c, Request_for_Agreement__r.Development_Term_Extension_1__c,
                                    Request_for_Agreement__r.Development_Term_Extension_2__c, Request_for_Agreement__r.Development_Term_Extension_3__c,
                                    Request_for_Agreement__r.Development_Term_Extension_4__c, Request_for_Agreement__r.Development_Term_Extension_5__c,
                                    StartDate, Request_for_Agreement__r.Development_Term_Length__c, Lease_Expiration_Amendment_formula__c  
                                    FROM Contract WHERE Lease_Expiration_Extension__c != null AND Current_Date__c != null
                                    AND Start_of_Construction__c = null AND Request_for_Agreement__r.Number_Of_Development_Term_Extensions__c !=null  
                                    AND Lease_Expiration_Extension__c <= :runDate ORDER BY Lease_Expiration_Extension__c ASC LIMIT 25];

        // List<Contract> contractRange = new List<Contract>();
        // for(Contract c: contracts){
        //     if(contractRange.size() != 25){
        //         if(runDate != null){
        //             if(c.Lease_Expiration_Extension__c == runDate){
        //                 contractRange.add(c);
        //             }
        //         }
        //     }
        // }
        return contracts;
    }
    public void execute(Database.BatchableContext info, List<Contract> contracts) {
        Date dateToday = date.today();
        List<Contract> updateContracts = new List<Contract>();
        // Iterate over the contracts
        for(Contract c: contracts){
            system.debug('Contract::'+c);
            // Initialize formulas -- TODO: add a null checks :)
            // {!Loop_Contracts.Lease_Expiration_Extension__c}
            Date initialDate;
            if(c.Request_for_Agreement__r.Development_Term_Length__c != null){
                initialDate = c.StartDate.addMonths(((Integer.valueOf(c.Request_for_Agreement__r.Development_Term_Length__c)-1) * 12));
            } else{
                initialDate = null;
            }
            system.debug('INITIAL DATE::'+ initialDate);

            Date contractExtension1;
            if(c.Request_for_Agreement__r.Development_Term_Extension_1__c != null){
                contractExtension1 = initialDate.addMonths((Integer.valueOf(c.Request_for_Agreement__r.Development_Term_Extension_1__c) * 12));
            } else{
                contractExtension1 = null;
            }
            system.debug('CONTRACT EXTENSION DATE 1::'+ contractExtension1);

            Date contractExtension2;
            if(c.Request_for_Agreement__r.Development_Term_Extension_2__c != null){
                contractExtension2 = contractExtension1.addMonths((Integer.valueOf(c.Request_for_Agreement__r.Development_Term_Extension_2__c) * 12));
            } else{
                contractExtension2 = null;
            }
            system.debug('CONTRACT EXTENSION DATE 2::'+ contractExtension2);

            Date contractExtension3;
            if(c.Request_for_Agreement__r.Development_Term_Extension_3__c != null){
                contractExtension3 = contractExtension2.addMonths((Integer.valueOf(c.Request_for_Agreement__r.Development_Term_Extension_3__c) * 12));
            } else{
                contractExtension3 = null;
            }
            system.debug('CONTRACT EXTENSION DATE 3::'+ contractExtension3);

            Date contractExtension4;
            if(c.Request_for_Agreement__r.Development_Term_Extension_4__c != null){
                contractExtension4 = contractExtension3.addMonths((Integer.valueOf(c.Request_for_Agreement__r.Development_Term_Extension_4__c) * 12));
            } else{
                contractExtension4 = null;
            }
            system.debug('CONTRACT EXTENSION DATE 4::'+ contractExtension4);

            Date contractExtension5;
            if(c.Request_for_Agreement__r.Development_Term_Extension_5__c != null){
                contractExtension5 = contractExtension4.addMonths((Integer.valueOf(c.Request_for_Agreement__r.Development_Term_Extension_5__c) * 12));
            } else{
                contractExtension5 = null;
            }
            system.debug('CONTRACT EXTENSION DATE 5::'+ contractExtension5);

            system.debug('INITIAL DATE:: '+initialDate);
            Date updateContractDate;
            if(c.Request_for_Agreement__r.Development_Term_Extension_5__c != null){
                if(c.Lease_Expiration_Extension__c.addMonths((Integer.valueOf(c.Request_for_Agreement__r.Development_Term_Extension_5__c) * 12)) <= contractExtension5){
                    
                    updateContractDate = contractExtension5;
                }
            }
            if(c.Request_for_Agreement__r.Development_Term_Extension_4__c != null){
                if(c.Lease_Expiration_Extension__c.addMonths((Integer.valueOf(c.Request_for_Agreement__r.Development_Term_Extension_4__c) * 12)) <= contractExtension4){
                    
                    updateContractDate = contractExtension4;
                }
            }
            if(c.Request_for_Agreement__r.Development_Term_Extension_3__c != null){
                if(c.Lease_Expiration_Extension__c.addMonths((Integer.valueOf(c.Request_for_Agreement__r.Development_Term_Extension_3__c) * 12)) <= contractExtension3){
                    
                    updateContractDate = contractExtension3;
                }
            }
            if(c.Request_for_Agreement__r.Development_Term_Extension_2__c != null){
                system.debug(c.Lease_Expiration_Extension__c.addMonths((Integer.valueOf(c.Request_for_Agreement__r.Development_Term_Extension_2__c) * 12)));
                system.debug(contractExtension2);
                if(c.Lease_Expiration_Extension__c.addMonths(((Integer.valueOf(c.Request_for_Agreement__r.Development_Term_Extension_2__c)-1) * 12)) <= contractExtension2){
                    Contract updateContract = new Contract();
                    
                    updateContractDate = contractExtension2;
                }
            }
            if(c.Request_for_Agreement__r.Development_Term_Extension_1__c != null){
                if(c.Lease_Expiration_Extension__c.addMonths((Integer.valueOf(c.Request_for_Agreement__r.Development_Term_Extension_1__c) * 12)) <= contractExtension1){
                    updateContractDate = contractExtension1;
                }
            }

            system.debug(updateContractDate);

            if(updateContractDate != null){
                Contract updateContract = new Contract();
                updateContract.Id = c.Id;
                updateContract.Lease_Expiration_Extension__c = updateContractDate;
        
                updateContracts.add(updateContract);
            }
        }

        system.debug(updateContracts);
        if(updateContracts.size() > 0) update updateContracts;
    }
    public void finish(Database.BatchableContext info) {
        
    }
}

/*
    Callout to run batch class

    // This class can only handle one at a time :)
    ContractExpirationExtensionBatchClass gdfc = new ContractExpirationExtensionBatchClass();
    Database.executeBatch(gdfc, 1);
*/