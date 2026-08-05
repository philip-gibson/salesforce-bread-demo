public with sharing class BreadOrderController {

  /**
   * Returns all Bread_Order__c records for the given Account.
   */
  @AuraEnabled(cacheable=true)
  public static List<Bread_Order__c> getBreadOrdersByAccountId(Id recordId) {
    try {
      return BreadOrderService.getBreadOrdersByAccountId(recordId);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
  
  /**
   * Returns the "Ready" Bread_Order__c records for the given Account.
   */
  @AuraEnabled(cacheable=true)
  public static List<Bread_Order__c> getReadyOrders(Id accountId) {
    try {
      return BreadOrderService.getReadyOrdersByAccountId(accountId);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}
