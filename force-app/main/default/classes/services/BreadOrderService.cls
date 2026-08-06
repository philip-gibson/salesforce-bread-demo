public with sharing class BreadOrderService {

  public static List<Bread_Order__c> createBreadOrders(List<BreadOrderDTO> requests) {
    // fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
    List<Bread_Order__c> breadOrders = new List<Bread_Order__c>();
    for (BreadOrderDTO r : requests) {
      breadOrders.add(new Bread_Order__c(Account__c = r.accountId, Bread__c = r.breadId, Quantity__c = r.quantity));
    }
    // IBreadOrders domain = (IBreadOrders) Application.Domain.newInstance(breadOrders, Bread_Order__c.SObjectType);
    // domain.applyDefaultsAndValidate();

    // for (Bread_Order__c bO : breadOrders) {
    //   uow.registerNew(bO);
    // }

    // uow.commitWork();
    insert breadOrders; // use insert while Application and UoW are still to do
    return breadOrders;
  }

  public static List<Bread_Order__c> getBreadOrdersByAccountId(Id recordId) {
    return BreadOrderSelector.getBreadOrdersByAccountId(recordId);
  }

  public static List<Bread_Order__c> getBreadOrdersByAccountIdAndStatus(Id accountId, String status) {
    return BreadOrderSelector.getBreadOrdersByAccountIdAndStatus(accountId, status);
  }

  public static List<Bread_Order__c> getReadyOrdersByAccountId(Id accountId) {
    return BreadOrderSelector.getBreadOrdersByAccountIdAndStatus(accountId, 'Ready');
  }
}
