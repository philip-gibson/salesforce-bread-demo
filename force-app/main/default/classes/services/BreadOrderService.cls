public with sharing class BreadOrderService {

  public static Bread_Order__c createBreadOrder() {
    return new Bread_Order__c();
  }

  public static List<Bread_Order__c> getBreadOrdersByAccountId(Id recordId) {
    return BreadOrderSelector.getBreadOrdersByAccountId(recordId);
  }

  public static List<Bread_Order__c> getReadyOrdersByAccountId(Id accountId) {
    return BreadOrderSelector.getReadyOrdersByAccountId(accountId);
  }
}
