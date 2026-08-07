/**
 * Domain class for the BreadOrder SObject, implemented per the
 * Apex Enterprise Patterns (fflib_SObjectDomain) approach.
 */
public with sharing class BreadOrders extends fflib_SObjectDomain {
  public static final String STATUS_NEW = 'New';
  public static final String STATUS_READY = 'Ready';

  public BreadOrders(List<Bread_Order__c> records) {
    super(records);
  }

  /**
   * Required factory so fflib_SObjectDomain.triggerHandler() can
   * construct this domain class from the trigger context.
   */
  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new BreadOrders(sObjectList);
    }
  }

  /**
	 * Called by the handleBeforeInsert()
	 **/
  public override void onApplyDefaults() {
    setStatusAndUnitPrice();
  }

  /**
	 * Called by the handleAfterUpdate()
	 **/
  public override void onValidate(Map<Id, SObject> existingRecords) {
    validateBreadNotChanged(existingRecords);
  }

  /**
   * Sets Unit_Price__c sourced from the lookup Bread__c record.
   */
  private void setStatusAndUnitPrice() {
    List<Bread_Order__c> newOrders = (List<Bread_Order__c>) Records;

    Set<Id> breadIds = new Set<Id>();
    for (Bread_Order__c order : newOrders) {
      setStatus(order);
      if (order.Bread__c != null) {
        breadIds.add(order.Bread__c);
      } else {
        order.Bread__c.addError('A Bread must be selected for the order.');
      }
    }

    if (breadIds.isEmpty()) {
      return;
    }

    Map<Id, Bread__c> breadsById = new Map<Id, Bread__c>(
      [SELECT Id, Unit_Price__c FROM Bread__c WHERE Id IN :breadIds]
    );

    for (Bread_Order__c order : newOrders) {
      if (order.Bread__c != null && breadsById.containsKey(order.Bread__c)) {
        order.Unit_Price__c = breadsById.get(order.Bread__c).Unit_Price__c;
      }
    }
  }

  /**
   * Checks the lookup Bread__c record has not been updated.
   */
  private void validateBreadNotChanged(Map<Id, SObject> existingRecords) {
    for (Bread_Order__c order : (List<Bread_Order__c>) Records) {
      Bread_Order__c oldOrder = (Bread_Order__c) existingRecords.get(order.Id);

      if (oldOrder != null && order.Bread__c != oldOrder.Bread__c) {
        order.Bread__c.addError(
          'The Bread cannot be changed once the order has been created.'
        );
      }
    }
  }

  /**
   * Sets default Status__c to 'New' if it is null.
   */
  private void setStatus(Bread_Order__c order) {
    if (order.Status__c == null)
      order.Status__c = 'New';
  }

  /**
   * Returns the set of active picklist API values for Bread_Order__c.Status__c.
   * Read dynamically via Schema describe so it stays in sync with the picklist.
   */
  public static Set<String> validStatusValues() {
    Set<String> values = new Set<String>();
    for (Schema.PicklistEntry entry : Bread_Order__c.Status__c.getDescribe().getPicklistValues()) {
      if (entry.isActive()) {
        values.add(entry.getValue());
      }
    }
    return values;
  }

  /**
   * Returns true if the given status is a valid, active Status__c picklist value.
   */
  public static Boolean isValidStatus(String status) {
    return status != null && validStatusValues().contains(status);
  }

  /**
   * Throws if the given status is not a valid, active Status__c picklist value.
   */
  public static void validateStatus(String status) {
    if (!isValidStatus(status)) {
      throw new BreadOrdersException(
        'Invalid Bread Order status: \'' + status + '\'. Valid values are: ' + validStatusValues()
      );
    }
  }

  public class BreadOrdersException extends Exception {}
}
