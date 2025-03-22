/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Project_InterestTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Project_InterestTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Project_Interest__c());
    }
}