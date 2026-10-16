@IsTest
private class LeadPriorityConsoleControllerTest {
  @TestSetup
  static void createLeads() {
    List<Lead> leads = new List<Lead>();
    for (Integer indexValue = 0; indexValue < 205; indexValue++) {
      leads.add(
        new Lead(
          LastName = 'Priority ' + indexValue,
          Company = 'Company ' + indexValue,
          LeadSource = Math.mod(indexValue, 2) == 0 ? 'Web' : null,
          Status = Math.mod(indexValue, 3) == 0 ? 'Working' : 'New'
        )
      );
    }
    insert leads;
    if (
      Schema.SObjectType.Lead.fields.getMap().containsKey('Lead_Priority__c')
    ) {
      for (Integer indexValue = 0; indexValue < leads.size(); indexValue++) {
        leads[indexValue]
          .put('Lead_Priority__c', indexValue < 203 ? 'High' : 'Normal');
      }
      update leads;
    }
  }

  @IsTest
  static void returnsDependencyErrorWhenPriorityFieldIsUnavailable() {
    LeadPriorityConsoleController.forceDependencyUnavailable = true;
    Test.startTest();
    LeadPriorityConsoleController.ConsoleData result = LeadPriorityConsoleController.getConsoleData();
    Test.stopTest();

    System.assertEquals(false, result.dependencyAvailable);
    System.assertNotEquals(null, result.errorMessage);
    System.assertEquals(0, result.highPriorityLeads.size());
    LeadPriorityConsoleController.forceDependencyUnavailable = false;
  }

  @IsTest
  static void returnsReadOnlyBoundedHighPriorityDataWhenDependencyExists() {
    if (
      !Schema.SObjectType.Lead.fields.getMap().containsKey('Lead_Priority__c')
    ) {
      return;
    }
    Integer dmlStatementsBefore = Limits.getDmlStatements();
    Test.startTest();
    LeadPriorityConsoleController.ConsoleData result = LeadPriorityConsoleController.getConsoleData();
    Test.stopTest();

    System.assertEquals(true, result.dependencyAvailable);
    System.assertEquals(200, result.highPriorityLeads.size());
    System.assertEquals(
      2,
      result.priorityRuleCount,
      'Web and blank are distinct rule sources.'
    );
    System.assertEquals('Normal', result.defaultPriority);
    System.assertEquals(203, result.highPriorityTodayCount);
    System.assertEquals(
      dmlStatementsBefore,
      Limits.getDmlStatements(),
      'The controller must remain read-only.'
    );
  }
}
