/**
 * Domain class for the BreadOrder SObject, implemented per the
 * Apex Enterprise Patterns (fflib_SObjectDomain) approach.
 */
public with sharing class BreadOrders extends fflib_SObjectDomain {
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
    setUnitPrice();
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
  private void setUnitPrice() {
    List<Bread_Order__c> newOrders = (List<Bread_Order__c>) Records;

    Set<Id> breadIds = new Set<Id>();
    for (Bread_Order__c order : newOrders) {
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
}
