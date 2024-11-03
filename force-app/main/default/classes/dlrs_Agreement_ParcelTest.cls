/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Agreement_ParcelTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Agreement_ParcelTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Agreement_Parcel__c());
    }
}