@IsTest
private class LeadRulesTest {
  private static final String OPEN_STATUS = 'Open - Not Contacted';

  @IsTest
  static void routesWebAndPartnerReferralLeadsToTheirQueues() {
    System.runAs(new User(Id = UserInfo.getUserId())) {
      Id inboundQueueId = queueId('Inbound_Sales_Queue');
      Id partnerQueueId = queueId('Partner_Sales_Queue');

      Lead webLead = newLead('Web', 'web@example.com', 'Web Company');
      Lead partnerLead = newLead(
        'Partner Referral',
        'partner@example.com',
        'Partner Company'
      );

      Database.DMLOptions options = new Database.DMLOptions();
      options.assignmentRuleHeader.useDefaultRule = true;
      webLead.setOptions(options);
      partnerLead.setOptions(options);

      Test.startTest();
      insert new List<Lead>{ webLead, partnerLead };
      Test.stopTest();

      Map<Id, Lead> insertedLeads = new Map<Id, Lead>(
        [
          SELECT OwnerId
          FROM Lead
          WHERE Id IN :new List<Id>{ webLead.Id, partnerLead.Id }
        ]
      );
      System.assertEquals(
        inboundQueueId,
        insertedLeads.get(webLead.Id).OwnerId
      );
      System.assertEquals(
        partnerQueueId,
        insertedLeads.get(partnerLead.Id).OwnerId
      );
    }
  }

  @IsTest
  static void preservesDefaultOwnershipAndAllowsDuplicateCandidatesForReview() {
    System.runAs(new User(Id = UserInfo.getUserId())) {
      Lead fallbackLead = newLead(
        'Phone Inquiry',
        'fallback@example.com',
        'Fallback Company'
      );
      insert fallbackLead;
      System.assertEquals(UserInfo.getUserId(), fallbackLead.OwnerId);

      Lead emailMatch = newLead(
        'Other',
        'duplicate@example.com',
        'First Company'
      );
      Lead sameEmail = newLead(
        'Other',
        'duplicate@example.com',
        'Second Company'
      );
      Lead nameCompanyMatch = newLead(
        'Other',
        'different@example.com',
        'Shared Company'
      );
      Lead sameNameCompany = newLead(
        'Other',
        'another@example.com',
        'Shared Company'
      );
      Lead nonMatch = newLead('Other', 'unique@example.com', 'Unique Company');
      nameCompanyMatch.FirstName = 'Taylor';
      sameNameCompany.FirstName = 'Taylor';
      nonMatch.FirstName = 'Jordan';

      Database.DMLOptions options = new Database.DMLOptions();
      options.duplicateRuleHeader.allowSave = true;
      emailMatch.setOptions(options);
      sameEmail.setOptions(options);
      nameCompanyMatch.setOptions(options);
      sameNameCompany.setOptions(options);
      nonMatch.setOptions(options);

      Test.startTest();
      Database.SaveResult[] results = Database.insert(
        new List<Lead>{
          emailMatch,
          sameEmail,
          nameCompanyMatch,
          sameNameCompany,
          nonMatch
        },
        false
      );
      Test.stopTest();

      for (Database.SaveResult result : results) {
        System.assert(
          result.isSuccess(),
          'Duplicate review rules must allow saves.'
        );
      }
    }
  }

  private static Id queueId(String developerName) {
    return [
      SELECT Id
      FROM Group
      WHERE DeveloperName = :developerName AND Type = 'Queue'
      LIMIT 1
    ]
    .Id;
  }

  private static Lead newLead(String leadSource, String email, String company) {
    return new Lead(
      FirstName = 'Alex',
      LastName = 'Lead Rules',
      Company = company,
      Email = email,
      Phone = '415-555-0100',
      LeadSource = leadSource,
      Status = OPEN_STATUS
    );
  }
}
