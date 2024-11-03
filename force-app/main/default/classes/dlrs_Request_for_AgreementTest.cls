/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Request_for_AgreementTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Request_for_AgreementTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Request_for_Agreement__c());
    }
}