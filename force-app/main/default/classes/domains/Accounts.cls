/**
 * Domain class for the Account SObject, implemented per the
 * Apex Enterprise Patterns (fflib_SObjectDomain) approach.
 */
public class Accounts extends fflib_SObjectDomain {

    private static final String REQUIRED_STATE = 'California';
    private static final Integer MIN_ZIP = 90001;
    private static final Integer MAX_ZIP = 96162;
    private static final String STATE_ERROR = 'State must be \'California\'';
    private static final String ZIP_ERROR = 'In the State of California, ZIP codes generally range from 90001 to 96162';
    private static final String DELETE_ERROR = 'This Account cannot be deleted because it has one or more active Bread Orders';

    public Accounts(List<Account> records) {
        super(records);
    }

    /**
     * Required factory so fflib_SObjectDomain.triggerHandler() can
     * construct this domain class from the trigger context.
     */
    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> sObjectList) {
            return new Accounts(sObjectList);
        }
    }

    public override void onBeforeInsert() {
        validateShippingState();
        validateShippingPostalCode();
    }

    public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
        validateShippingState();
        validateShippingPostalCode();
    }

    public override void onBeforeDelete() {
        checkBreadOrders();
    }

    /**
     * Normalizes "california" (any casing) to "California" and
     * raises a field error for any other value.
     */
    private void validateShippingState() {
        for (Account acc : (List<Account>) Records) {
            if (acc.ShippingState.equalsIgnoreCase(REQUIRED_STATE)) {
                acc.ShippingState = REQUIRED_STATE;
            } else {
                acc.ShippingState.addError(STATE_ERROR);
            }
        }
    }

    /**
     * Ensures ShippingPostalCode is a 5-digit number within the
     * California ZIP code range (90001-96162).
     */
    private void validateShippingPostalCode() {
        for (Account acc : (List<Account>) Records) {
            String zipRaw = acc.ShippingPostalCode;

            String trimmedZip = zipRaw.trim();

            if (!Pattern.matches('^\\d{5}$', trimmedZip)) {
                acc.ShippingPostalCode.addError(ZIP_ERROR);
                continue;
            }

            Integer zipValue = Integer.valueOf(trimmedZip);
            if (zipValue < MIN_ZIP || zipValue > MAX_ZIP) {
                acc.ShippingPostalCode.addError(ZIP_ERROR);
            }
        }
    }

    /**
     * Prevents deletion of any Account that has at least one related
     * Bread_Order__c with Status__c = 'Ready'. Accounts with no related
     * orders, or whose orders are all 'Delivered' or 'Cancelled', delete
     * normally.
     */
    private void checkBreadOrders() {
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : (List<Account>) Records) {
            accountIds.add(acc.Id);
        }

        // Collect the Accounts that have at least one 'Ready' order.
        Set<Id> accountsWithReadyOrders = new Set<Id>();
        for (Bread_Order__c order : [
            SELECT Account__c
            FROM Bread_Order__c
            WHERE Account__c IN :accountIds AND Status__c = 'Ready'
        ]) {
            accountsWithReadyOrders.add(order.Account__c);
        }

        for (Account acc : (List<Account>) Records) {
            if (accountsWithReadyOrders.contains(acc.Id)) {
                acc.addError(DELETE_ERROR);
            }
        }
    }
}
