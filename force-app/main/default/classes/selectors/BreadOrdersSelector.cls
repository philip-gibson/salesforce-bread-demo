public with sharing class BreadOrdersSelector {
  /**
   * Returns all Bread_Order__c records for the given Account ID.
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
   * Returns the Bread_Order__c detail records for the given Account ID and Status.
   */
  public static List<Bread_Order__c> getBreadOrdersByAccountIdAndStatus(Id accountId, String status) {
    BreadOrders.validateStatus(status);

    if (accountId == null) {
      return new List<Bread_Order__c>();
    }

    return [
      SELECT Id, Total__c, Status__c, Quantity__c, Bread__r.Name
      FROM Bread_Order__c
      WHERE Account__c = :accountId
        AND Status__c = :status
      WITH USER_MODE
      ORDER BY Bread__r.Name
    ];
  }
}
