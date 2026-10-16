/** Provides read-only, dependency-aware data for Lead Priority Console. */
public with sharing class LeadPriorityConsoleController {
  private static final String PRIORITY_FIELD = 'Lead_Priority__c';
  private static final Integer MAX_HIGH_PRIORITY_LEADS = 200;

  @TestVisible
  private static Boolean forceDependencyUnavailable = false;

  /** Response contract for the console. */
  public class ConsoleData {
    @AuraEnabled
    public Boolean dependencyAvailable;
    @AuraEnabled
    public String errorMessage;
    @AuraEnabled
    public Integer priorityRuleCount;
    @AuraEnabled
    public Integer highPriorityTodayCount;
    @AuraEnabled
    public String defaultPriority;
    @AuraEnabled
    public List<RuleMapping> ruleMappings;
    @AuraEnabled
    public List<LeadRow> highPriorityLeads;
  }

  /** A distinct Lead Source and priority pair. */
  public class RuleMapping {
    @AuraEnabled
    public String leadSource;
    @AuraEnabled
    public String priority;
    @AuraEnabled
    public String mappingKey;

    /** Creates a display-safe mapping. */
    public RuleMapping(String leadSource, String priority) {
      this.leadSource = String.isBlank(leadSource)
        ? 'Other / Blank'
        : leadSource;
      this.priority = priority;
      this.mappingKey = this.leadSource + '-' + priority;
    }
  }

  /** Read-only Lead table and preview row. */
  public class LeadRow {
    @AuraEnabled
    public Id id;
    @AuraEnabled
    public String name;
    @AuraEnabled
    public String company;
    @AuraEnabled
    public String leadSource;
    @AuraEnabled
    public String priority;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public Id ownerId;
    @AuraEnabled
    public String ownerName;
    @AuraEnabled
    public Datetime createdDate;

    /** Converts a queried Lead to its client-safe shape. */
    public LeadRow(Lead lead, Boolean includeOwnerName) {
      id = lead.Id;
      name = lead.Name;
      company = lead.Company;
      leadSource = lead.LeadSource;
      priority = (String) lead.get(PRIORITY_FIELD);
      status = lead.Status;
      ownerId = lead.OwnerId;
      ownerName = includeOwnerName && lead.Owner != null
        ? lead.Owner.Name
        : null;
      createdDate = lead.CreatedDate;
    }
  }

  /** Returns console data without modifying Salesforce records. */
  @AuraEnabled(cacheable=true)
  public static ConsoleData getConsoleData(
    String searchTerm,
    String leadSource,
    String status
  ) {
    ConsoleData result = new ConsoleData();
    result.dependencyAvailable = hasRequiredAccess();
    result.defaultPriority = 'Normal';
    result.ruleMappings = new List<RuleMapping>();
    result.highPriorityLeads = new List<LeadRow>();
    result.priorityRuleCount = 0;
    result.highPriorityTodayCount = 0;

    if (!result.dependencyAvailable) {
      result.errorMessage = 'Lead Priority is unavailable. Deploy the Lead Priority field and activate the Lead priority flow before using this console.';
      return result;
    }

    try {
      List<AggregateResult> mappings = Database.query(
        'SELECT LeadSource, ' +
          PRIORITY_FIELD +
          ' priority ' +
          'FROM Lead GROUP BY LeadSource, ' +
          PRIORITY_FIELD
      );
      Set<String> prioritySources = new Set<String>();
      for (AggregateResult mapping : mappings) {
        String source = (String) mapping.get('LeadSource');
        String priority = (String) mapping.get('priority');
        result.ruleMappings.add(new RuleMapping(source, priority));
        if (priority == 'High') {
          prioritySources.add(String.isBlank(source) ? '' : source);
        }
      }
      result.priorityRuleCount = prioritySources.size();

      List<AggregateResult> todayCounts = Database.query(
        'SELECT COUNT(Id) total FROM Lead WHERE ' +
          PRIORITY_FIELD +
          ' = \'High\' AND CreatedDate = TODAY'
      );
      result.highPriorityTodayCount = (Integer) todayCounts[0].get('total');

      Boolean includeOwnerName = canReadOwnerName();
      String ownerNameField = includeOwnerName ? ', Owner.Name' : '';
      List<String> leadFilters = new List<String>{
        PRIORITY_FIELD + ' = \'High\''
      };
      String searchPattern;
      if (!String.isBlank(searchTerm)) {
        searchPattern = '%' + searchTerm.trim() + '%';
        leadFilters.add(
          '(Name LIKE :searchPattern OR Company LIKE :searchPattern)'
        );
      }
      String sourceFilter = String.isBlank(leadSource) ? null : leadSource;
      if (sourceFilter != null) {
        leadFilters.add('LeadSource = :sourceFilter');
      }
      String statusFilter = String.isBlank(status) ? null : status;
      if (statusFilter != null) {
        leadFilters.add('Status = :statusFilter');
      }
      List<Lead> highPriorityLeads = Database.query(
        'SELECT Id, Name, Company, LeadSource, ' +
          PRIORITY_FIELD +
          ', Status, OwnerId' +
          ownerNameField +
          ', CreatedDate FROM Lead WHERE ' +
          String.join(leadFilters, ' AND ') +
          ' ORDER BY CreatedDate DESC LIMIT ' +
          MAX_HIGH_PRIORITY_LEADS
      );
      for (Lead lead : highPriorityLeads) {
        result.highPriorityLeads.add(new LeadRow(lead, includeOwnerName));
      }
    } catch (Exception caughtException) {
      result.dependencyAvailable = false;
      result.errorMessage = 'Lead Priority data is unavailable. Please verify your access and the Lead Priority deployment.';
      result.ruleMappings.clear();
      result.highPriorityLeads.clear();
      result.priorityRuleCount = 0;
      result.highPriorityTodayCount = 0;
    }
    return result;
  }

  private static Boolean hasRequiredAccess() {
    if (Test.isRunningTest() && forceDependencyUnavailable) {
      return false;
    }
    Schema.DescribeSObjectResult leadDescribe = Lead.SObjectType.getDescribe(
      SObjectDescribeOptions.DEFERRED
    );
    if (
      !leadDescribe.isAccessible() ||
      !leadDescribe.fields.getMap().containsKey(PRIORITY_FIELD)
    ) {
      return false;
    }
    for (
      String fieldName : new List<String>{
        'Id',
        'Name',
        'Company',
        'LeadSource',
        PRIORITY_FIELD,
        'Status',
        'OwnerId',
        'CreatedDate'
      }
    ) {
      if (
        !leadDescribe.fields.getMap()
          .get(fieldName)
          .getDescribe()
          .isAccessible()
      ) {
        return false;
      }
    }
    return true;
  }

  private static Boolean canReadOwnerName() {
    Schema.DescribeSObjectResult userDescribe = User.SObjectType.getDescribe(
      SObjectDescribeOptions.DEFERRED
    );
    return userDescribe.isAccessible() &&
      Schema.SObjectType.User.fields.Name.getDescribe().isAccessible();
  }
}
