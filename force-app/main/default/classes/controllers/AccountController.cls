public with sharing class AccountController {
  /**
   * Create a new Bread_Order__c record for the given account.
   */
  @AuraEnabled
  public static Bread_Order__c createBreadOrder(Id accountId) {
    try {
      return BreadOrderService.createBreadOrder();
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
