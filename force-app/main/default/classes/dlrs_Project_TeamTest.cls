/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Project_TeamTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Project_TeamTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Project_Team__c());
    }
}