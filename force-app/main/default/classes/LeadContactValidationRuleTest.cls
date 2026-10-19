@IsTest
private class LeadContactValidationRuleTest {
  private static final String QUALIFIED_STATUS = 'Closed - Converted';
  private static final String OPEN_STATUS = 'Open - Not Contacted';
  private static final String ERROR_MESSAGE = 'Provide an email address and phone number before qualifying this Lead.';

  @IsTest
  static void qualifiedLeadWithContactDetailsSaves() {
    System.runAs(new User(Id = UserInfo.getUserId())) {
      Lead qualifiedLead = newLead(
        QUALIFIED_STATUS,
        'qualified@example.com',
        '415-555-0100'
      );

      Database.SaveResult result = Database.insert(qualifiedLead, false);

      System.assert(
        result.isSuccess(),
        'A qualified Lead with complete contact details should save.'
      );
    }
  }

  @IsTest
  static void qualifiedLeadMissingEmailIsBlocked() {
    System.runAs(new User(Id = UserInfo.getUserId())) {
      Lead qualifiedLead = newLead(QUALIFIED_STATUS, null, '415-555-0101');

      Database.SaveResult result = Database.insert(qualifiedLead, false);

      System.assert(
        !result.isSuccess(),
        'A Lead without an email should not qualify.'
      );
      assertContactDetailsError(result);
    }
  }

  @IsTest
  static void qualifiedLeadMissingPhoneIsBlocked() {
    System.runAs(new User(Id = UserInfo.getUserId())) {
      Lead qualifiedLead = newLead(QUALIFIED_STATUS, 'phone@example.com', null);

      Database.SaveResult result = Database.insert(qualifiedLead, false);

      System.assert(
        !result.isSuccess(),
        'A Lead without a phone number should not qualify.'
      );
      assertContactDetailsError(result);
    }
  }

  @IsTest
  static void incompleteOpenLeadSaves() {
    System.runAs(new User(Id = UserInfo.getUserId())) {
      Lead openLead = newLead(OPEN_STATUS, null, null);

      Database.SaveResult result = Database.insert(openLead, false);

      System.assert(
        result.isSuccess(),
        'An incomplete Lead in an open status should save.'
      );
    }
  }

  @IsTest
  static void incompleteLeadCanBeCompletedThenQualified() {
    System.runAs(new User(Id = UserInfo.getUserId())) {
      Lead openLead = newLead(OPEN_STATUS, null, null);
      insert openLead;

      openLead.Email = 'completed@example.com';
      openLead.Phone = '415-555-0102';
      openLead.Status = QUALIFIED_STATUS;
      Database.SaveResult result = Database.update(openLead, false);

      System.assert(
        result.isSuccess(),
        'A completed Lead should be allowed to qualify.'
      );
    }
  }

  private static Lead newLead(String status, String email, String phone) {
    return new Lead(
      LastName = 'Validation Test',
      Company = 'AG-331 Test Company',
      Status = status,
      Email = email,
      Phone = phone
    );
  }

  private static void assertContactDetailsError(Database.SaveResult result) {
    System.assert(!result.isSuccess(), 'The save should be blocked.');
    System.assertEquals(
      1,
      result.getErrors().size(),
      'Expected one validation error.'
    );
    System.assertEquals(ERROR_MESSAGE, result.getErrors()[0].getMessage());
  }
}
