/**
 * @description       : Scheduled Batch Class which checks for Contracts whose Start of Construction date
 * has changed, and updates its related Lease Expiration Extension field based on the most recently used 
 * Term Extension from the related RFA. If the Lease Expiration Extension is in the past, it will be updated
 * based on the value of the next extension term, in years (e.g. 2 = 2 years, 0.5 = 6 months), up until the final
 * term extension.
 * @author            : NuAge - AKelly
 * @last modified on  : 12-26-2024
 * @last modified by  : NuAge - Akelly
**/
public with sharing class ContractExpirationExtensionBatchClass implements Database.Batchable<Contract> {
    public Date testDate;

    public Iterable<Contract> start(Database.BatchableContext BC) {
        Date runDate;
        if (!Test.isRunningTest()) {
            runDate = Date.today().addDays(-1); // Adjust date for testing
        } else {
            runDate = testDate.addDays(-1);
        }

        List<Contract> contracts = [SELECT Id, Name, ContractNumber, Lease_Expiration_Extension__c, 
                                    Request_for_Agreement__r.Development_Term_Extension_1__c,
                                    Request_for_Agreement__r.Development_Term_Extension_2__c,
                                    Request_for_Agreement__r.Development_Term_Extension_3__c,
                                    Request_for_Agreement__r.Development_Term_Extension_4__c,
                                    Request_for_Agreement__r.Development_Term_Extension_5__c,
                                    Request_for_Agreement__r.Development_Term_Extension_6__c,
                                    Request_for_Agreement__r.Development_Term_Extension_7__c,
                                    Request_for_Agreement__r.Development_Term_Extension_8__c,
                                    Request_for_Agreement__r.Development_Term_Extension_9__c,
                                    Request_for_Agreement__r.Development_Term_Extension_10__c,
                                    StartDate, Request_for_Agreement__r.Development_Term_Length__c,
                                    Lease_Expiration_Amendment_formula__c, Last_Used_Term_Extension__c
                                    FROM Contract 
                                    WHERE Lease_Expiration_Extension__c != null 
                                    AND Current_Date__c != null
                                    // AND ContractNumber = '00002178' // GREENBEANS FOR TESTING PURPOSES ONLY
                                    // AND ContractNumber = '00002185' // testing west team FOR TESTING PURPOSES ONLY
                                    AND Start_of_Construction__c = null 
                                    AND Request_for_Agreement__r.Number_Of_Development_Term_Extensions__c != null  
                                    AND Lease_Expiration_Extension__c <= :runDate 
                                    ORDER BY Lease_Expiration_Extension__c ASC 
                                    LIMIT 20];
        System.debug('Query returned ' + contracts.size() + ' contracts.');
        return contracts;
    }

    public void execute(Database.BatchableContext info, List<Contract> contracts) {
        List<Contract> updateContracts = new List<Contract>();
        System.debug('BEFFORE - LIMITS USED: ' + Limits.getCPUTime());
        System.debug('BEFORE - LIMITS AVAILABLLE - ' + Limits.getLimitCPUTime());
        for (Contract c : contracts) {
            Date initialDate = c.Lease_Expiration_Extension__c;
            
            // Skip contract if already in the future
            if (c.StartDate > Date.today()) {
                continue;
            }

            List<String> extensionValues = new List<String>{
                c.Request_for_Agreement__r.Development_Term_Extension_1__c,
                c.Request_for_Agreement__r.Development_Term_Extension_2__c,
                c.Request_for_Agreement__r.Development_Term_Extension_3__c,
                c.Request_for_Agreement__r.Development_Term_Extension_4__c,
                c.Request_for_Agreement__r.Development_Term_Extension_5__c,
                c.Request_for_Agreement__r.Development_Term_Extension_6__c,
                c.Request_for_Agreement__r.Development_Term_Extension_7__c,
                c.Request_for_Agreement__r.Development_Term_Extension_8__c,
                c.Request_for_Agreement__r.Development_Term_Extension_9__c,
                c.Request_for_Agreement__r.Development_Term_Extension_10__c
            };

            Integer finalValidExtension = findFinalValidExtension(extensionValues);
            System.debug('Contract ' + c.Name + ' has ' + finalValidExtension + ' valid extensions');
            Integer lastUsedExtension = (c.Last_Used_Term_Extension__c != null) ? c.Last_Used_Term_Extension__c.intValue() : 0;

            Date updateContractDate = initialDate;

            Boolean expirationUpdated = false;

            if (lastUsedExtension >= finalValidExtension) System.debug('Contract ' + c.Name + ' has surpassed its final valid extension term');

            while (updateContractDate <= Date.today() && lastUsedExtension < finalValidExtension) {
                String nextExtensionValue = extensionValues[lastUsedExtension];
                System.debug('next extension value? '  + nextExtensionValue);
                if (nextExtensionValue != null) {
                    Decimal monthsToAdd = Decimal.valueOf(nextExtensionValue) * 12;

                    if (updateContractDate.addMonths(monthsToAdd.intValue()) > c.Lease_Expiration_Extension__c) {
                        updateContractDate = updateContractDate.addMonths(monthsToAdd.intValue());
                        lastUsedExtension++;
                        expirationUpdated = true;
                    }
                }

                if (expirationUpdated && updateContractDate > Date.today()) {
                    break;
                }
            }

            if (expirationUpdated && updateContractDate != c.Lease_Expiration_Extension__c) {
                System.debug('AFTER - LIMITS USED: ' + Limits.getCPUTime());
                System.debug('AFTER - LIMITS AVAILABLLE - ' + Limits.getLimitCPUTime());
                Contract updateContract = new Contract(Id = c.Id);
                updateContract.Lease_Expiration_Extension__c = updateContractDate;
                updateContract.Last_Used_Term_Extension__c = lastUsedExtension == 0 ? null : lastUsedExtension;
                System.debug('Updating: ' + updateContract.Name + ' expiry to: ' + updateContractDate + '. Last used extension is: ' + lastUsedExtension);
                updateContracts.add(updateContract);
            }
        }

        if (!updateContracts.isEmpty()) {
            update updateContracts;
            // System.enqueueJob(new ContractExpirationUpdateQueueable(updateContracts));
        }
    }

    private Integer findFinalValidExtension(List<String> extensionValues) {
        Integer validExtensionsCount = 0;
        for (Integer i = 0; i < extensionValues.size(); i++) {
            if (extensionValues[i] != null && extensionValues[i] != '') {
                validExtensionsCount++;
            }
        }
        return validExtensionsCount - 1;
    }

    public void finish(Database.BatchableContext info) {
        System.debug('Batch process completed.');
    }
}
