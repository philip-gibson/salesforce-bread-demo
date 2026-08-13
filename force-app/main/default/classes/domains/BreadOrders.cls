/**
 * Domain class for the BreadOrder SObject, implemented per the
 * Apex Enterprise Patterns (fflib_SObjectDomain) approach.
 */
public with sharing class BreadOrders extends fflib_SObjects implements IBreadOrders {
  public static final String STATUS_NEW = 'New';
  public static final String STATUS_READY = 'Ready';

  public static IBreadOrders newInstance(List<Bread_Order__c> recordList) {
		return (IBreadOrders) Application.Domain.newInstance(recordList);
	}

	public static IBreadOrders newInstance(Set<Id> recordIdSet) {
		return (IBreadOrders) Application.Domain.newInstance(recordIdSet);
	}

  public BreadOrders(List<SObject> sObjectList) {
    super(sObjectList);
  }

  public class Constructor implements fflib_IDomainConstructor {
		public fflib_SObjects construct(List<Object> objectList) {
			return new BreadOrders((List<SObject>) objectList);
		}
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
