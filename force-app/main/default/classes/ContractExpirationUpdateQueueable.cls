public class ContractExpirationUpdateQueueable implements Queueable {
    private List<Contract> contractsToUpdate;

    // Constructor to pass the list of contracts to update
    public ContractExpirationUpdateQueueable(List<Contract> contracts) {
        this.contractsToUpdate = contracts;
    }

    public void execute(QueueableContext context) {
        try {
            if (!contractsToUpdate.isEmpty()) {
                update contractsToUpdate;
                System.debug('Successfully updated ' + contractsToUpdate.size() + ' contracts.');
            }
        } catch (Exception e) {
            System.debug('Error in Queueable Job: ' + e.getMessage());
        }
    }
}
