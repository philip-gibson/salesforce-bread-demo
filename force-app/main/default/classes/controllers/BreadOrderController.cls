public with sharing class BreadOrderController {  
  /**
   * Returns the "Ready" Bread_Order__c records for the given Account.
   */
  @AuraEnabled(cacheable=true)
  public static List<Bread_Order__c> getReadyOrders(Id accountId) {
    try {
      return BreadOrdersService.getBreadOrdersByAccountIdAndStatus(accountId, 'Ready');
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}
