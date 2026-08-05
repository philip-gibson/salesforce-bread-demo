public with sharing class BreadOrderSelector {

  private static final String READY_STATUS = 'Ready';

  /**
   * Returns all Bread_Order__c records for the given Account.
   */
  public static List<Bread_Order__c> getBreadOrdersByAccountId(Id accountId) {
    if (accountId == null) {
      return new List<Bread_Order__c>();
    }

    return [
      SELECT Id, Total__c, Status__c, Quantity__c, Bread__c, Bread__r.Name
      FROM Bread_Order__c
      WHERE Account__c = :accountId
      WITH USER_MODE
      ORDER BY CreatedDate DESC
    ];
  }

  /**
   * Returns the "Ready" Bread_Order__c detail records for the given Account
   * (via the Account__c master-detail relationship).
   *
   * Returns an empty list when accountId is null, so callers can safely
   * invoke this before an account has been selected.
   */
  public static List<Bread_Order__c> getReadyOrdersByAccountId(Id accountId) {
    if (accountId == null) {
      return new List<Bread_Order__c>();
    }

    return [
      SELECT Id, Total__c, Status__c, Quantity__c, Bread__r.Name
      FROM Bread_Order__c
      WHERE Account__c = :accountId
        AND Status__c = :READY_STATUS
      WITH USER_MODE
      ORDER BY Bread__r.Name
    ];
  }
}
