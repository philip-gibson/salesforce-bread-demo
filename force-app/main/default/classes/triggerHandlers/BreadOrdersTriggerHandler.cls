public with sharing class BreadOrdersTriggerHandler extends fflib_SObjectDomain {

  @TestVisible private static final String REQUIRED_STATE = 'California';

  public BreadOrdersTriggerHandler(List<SObject> sObjectList) {
    super(sObjectList);
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
		public fflib_SObjectDomain construct(List<SObject> sObjectList) {
			return new BreadOrdersTriggerHandler(sObjectList);
		}
	}

  /**
	 * Called by the handleBeforeInsert()
	 **/
  public override void onApplyDefaults() {
    setStatusAndUnitPrice();
  }

  public override void onBeforeInsert() {
    validateStateOfCalifornia();
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
   * Checks the Account__c has shipping state "California".
   */
  private void validateStateOfCalifornia() {
    List<Bread_Order__c> orders = (List<Bread_Order__c>) Records;
    Set<Id> accountIds = new Set<Id>();
    for (Bread_Order__c order : orders) {
      if (order.Account__c != null) {
        accountIds.add(order.Account__c);
      }
    }

    Map<Id, Account> accMap = new Map<Id, Account>([SELECT Id, ShippingState FROM Account WHERE Id IN :accountIds]);
    
    for (Bread_Order__c order : orders) {
      Account acc = accMap.get(order.Account__c);
      if (acc == null || acc.ShippingState != REQUIRED_STATE) {
        order.addError(
          'Bread Orders are only for Accounts whose Shipping State is California.'
        );
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
}
