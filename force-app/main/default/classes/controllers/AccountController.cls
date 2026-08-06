public with sharing class AccountController {
  /**
   * Create a new Bread_Order__c record for the given account.
   */
  @AuraEnabled
  public static Bread_Order__c createBreadOrder(BreadOrderDTO breadOrder) {
    try {
      return BreadOrderService.createBreadOrders(new List<BreadOrderDTO>{ breadOrder })[0];
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  /**
   * Returns the "New" Bread_Order__c records for the given Account.
   */
  @AuraEnabled(cacheable=true)
  public static List<Bread_Order__c> getNewBreadOrders(Id accountId) {
    try {
      return BreadOrderService.getBreadOrdersByAccountIdAndStatus(accountId, 'New');
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  /**
   * Returns all Bread__c records.
   */
  @AuraEnabled(cacheable=true)
  public static List<Bread__c> getBreads() {
    try {
      return BreadService.getBreads();
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}
