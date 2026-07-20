/**
 * Accounts
 *
 * Domain class for the Account SObject, implemented per the
 * Apex Enterprise Patterns (fflib_SObjectDomain) approach.
 *
 * Business rules enforced:
 *   1. ShippingState must be "California".
 *        - If entered as "california" (any case variant), it is
 *          auto-corrected to the properly-cased "California".
 *        - Any other value raises a field-level error.
 *   2. ShippingPostalCode must be a 5-digit numeric ZIP code
 *      between 90001 and 96162 inclusive.
 */
public class Accounts extends fflib_SObjectDomain {

    private static final String REQUIRED_STATE = 'California';
    private static final Integer MIN_ZIP = 90001;
    private static final Integer MAX_ZIP = 96162;
    private static final String STATE_ERROR = 'State must be \'California\'';
    private static final String ZIP_ERROR = 'In the State of California, ZIP codes generally range from 90001 to 96162';

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

    /**
     * Normalizes "california" (any casing) to "California" and
     * raises a field error for any other value.
     */
    private void validateShippingState() {
        for (Account acc : (List<Account>) Records) {
            if (String.isBlank(acc.ShippingState)) {
                continue;
            }

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

            if (String.isBlank(zipRaw)) {
                continue;
            }

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
}
