public with sharing class AccountController {
  /**
   * Create a new Bread_Order__c record for the given account.
   */
  @AuraEnabled
  public static void createBreadOrder(BreadOrderDTO breadOrder) {
    try {
      BreadOrdersService.createBreadOrders(new List<BreadOrderDTO>{ breadOrder });
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  /**
   * Set status for Bread_Order__c records to 'Ready'.
   */
  @AuraEnabled
  public static void setBreadOrdersToReady(List<Id> breadOrderIds) {
    try {
      BreadOrdersService.setBreadOrdersToStatus(breadOrderIds, BreadOrders.STATUS_READY);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  /**
   * Returns the 'New' Bread_Order__c records for the given Account.
   */
  @AuraEnabled(cacheable=true)
  public static List<Bread_Order__c> getNewBreadOrders(Id accountId) {
    try {
      return BreadOrdersService.getBreadOrdersByAccountIdAndStatus(accountId, BreadOrders.STATUS_NEW);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  /**
   * Returns all Bread_Order__c records for the given Account.
   */
  @AuraEnabled(cacheable=true)
  public static List<Bread_Order__c> getBreadOrdersByAccountId(Id recordId) {
    try {
      return BreadOrdersService.getBreadOrdersByAccountId(recordId);
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
      return BreadsService.getBreads();
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}
