public with sharing class BreadOrderService {

  public static List<Bread_Order__c> createBreadOrders(List<BreadOrderDTO> requests) {
    fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
    List<Bread_Order__c> breadOrders = new List<Bread_Order__c>();
    for (BreadOrderDTO r : requests) {
      Bread_Order__c bO = new Bread_Order__c(Account__c = r.accountId, Bread__c = r.breadId, Quantity__c = r.quantity);
      breadOrders.add(bO);
      uow.registerNew(bO);
    }

    uow.commitWork();
    return breadOrders;
  }

  public static List<Bread_Order__c> getBreadOrdersByAccountId(Id recordId) {
    return BreadOrdersSelector.getBreadOrdersByAccountId(recordId);
  }

  public static List<Bread_Order__c> getBreadOrdersByAccountIdAndStatus(Id accountId, String status) {
    return BreadOrdersSelector.getBreadOrdersByAccountIdAndStatus(accountId, status);
  }

  public static List<Bread_Order__c> setBreadOrdersToStatus(List<Id> breadOrderIds, String status) {
    BreadOrders.validateStatus(status);

    fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
    List<Bread_Order__c> breadOrders = new List<Bread_Order__c>();
    for (Id id : breadOrderIds) {
      breadOrders.add(new Bread_Order__c(Id = id, Status__c = status));
    }

    for (Bread_Order__c bO : breadOrders) {
      uow.registerDirty(bO);
    }

    uow.commitWork();
    return breadOrders;
  }
}
