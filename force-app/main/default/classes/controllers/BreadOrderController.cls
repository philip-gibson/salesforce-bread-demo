public with sharing class BreadOrderController {

  /**
   * LWC entry point: returns the "Ready" Bread_Order__c records for the
   * given Account. Cacheable so it can be used with @wire.
   */
  @AuraEnabled(cacheable=true)
  public static List<Bread_Order__c> getReadyOrders(Id accountId) {
    try {
      return BreadOrderSelector.getReadyOrdersByAccountId(accountId);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}
