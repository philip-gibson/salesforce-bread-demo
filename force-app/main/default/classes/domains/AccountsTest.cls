/**
 * Unit tests for the Accounts domain class, which holds all of the
 * Account trigger business logic:
 *   - ShippingStateCode normalization and validation
 *   - ShippingPostalCode format and California range validation
 *   - Guard that blocks deletion of Accounts with active (Ready) Bread Orders
 */
@isTest
private class AccountsTest {
  private static final String VALID_STATE_CODE = 'CA';
  private static final String VALID_ZIP = '90210';

  // -------------------------------------------------------------------
  // Test data helpers
  // -------------------------------------------------------------------

  private static Account buildAccount(
    String name,
    String shippingStateCode,
    String shippingPostalCode
  ) {
    Account acc = new Account(
      Name = name,
      ShippingPostalCode = shippingPostalCode
    );

    // State and Country picklists are enabled in this org, so a country code
    // must be supplied before a state code can be set. The ISO codes live in
    // ShippingCountryCode and ShippingStateCode.
    if (String.isNotBlank(shippingStateCode)) {
      acc.ShippingCountryCode = 'US';
      acc.ShippingStateCode = shippingStateCode;
    }

    return acc;
  }

  private static Account insertValidAccount(String name) {
    Account acc = buildAccount(name, VALID_STATE_CODE, VALID_ZIP);
    insert acc;
    return acc;
  }

  private static Bread__c insertBread() {
    Bread__c bread = new Bread__c(
      Name = 'White Bread',
      External_ID__c = 'White_Bread',
      Unit_Price__c = 2.39
    );
    insert bread;
    return bread;
  }

  private static void insertBreadOrder(
    Id accountId,
    Id breadId,
    String status
  ) {
    insert new Bread_Order__c(
      Account__c = accountId,
      Bread__c = breadId,
      Status__c = status,
      Quantity__c = 3
    );
  }

  // -------------------------------------------------------------------
  // ShippingStateCode normalization and validation
  // -------------------------------------------------------------------

  @isTest
  static void testLowercaseCaliforniaIsCapitalized() {
    Account acc = buildAccount('Test Account 1', 'ca', VALID_ZIP);

    Test.startTest();
    insert acc;
    Test.stopTest();

    Account result = [
      SELECT ShippingStateCode
      FROM Account
      WHERE Id = :acc.Id
    ];
    System.assertEquals(
      VALID_STATE_CODE,
      result.ShippingStateCode,
      'Lowercase "ca" should be normalized to "CA"'
    );
  }

  @isTest
  static void testMixedCaseCaliforniaIsCapitalized() {
    Account acc = buildAccount('Test Account 1b', 'Ca', VALID_ZIP);

    Test.startTest();
    insert acc;
    Test.stopTest();

    Account result = [
      SELECT ShippingStateCode
      FROM Account
      WHERE Id = :acc.Id
    ];
    System.assertEquals(
      VALID_STATE_CODE,
      result.ShippingStateCode,
      'Mixed-case "Ca" should be normalized to "CA"'
    );
  }

  @isTest
  static void testUppercaseCaliforniaIsCapitalized() {
    Account acc = buildAccount('Test Account 1c', 'CA', VALID_ZIP);

    Test.startTest();
    insert acc;
    Test.stopTest();

    Account result = [
      SELECT ShippingStateCode
      FROM Account
      WHERE Id = :acc.Id
    ];
    System.assertEquals(
      VALID_STATE_CODE,
      result.ShippingStateCode,
      'Uppercase "CA" should remain "CA"'
    );
  }

  @isTest
  static void testInvalidStateThrowsError() {
    Account acc = buildAccount('Test Account 2', 'NV', VALID_ZIP);

    Test.startTest();
    Database.SaveResult result = Database.insert(acc, false);
    Test.stopTest();

    System.assertEquals(
      false,
      result.isSuccess(),
      'Insert should fail for non-California state'
    );
    System.assertEquals(
      1,
      result.getErrors().size(),
      'Only the state error should be reported'
    );
    System.assertEquals(
      Accounts.STATE_ERROR,
      result.getErrors()[0].getMessage(),
      'Error message should match expected text'
    );
  }

  @isTest
  static void testLowercaseCaliforniaIsCapitalizedOnUpdate() {
    Account acc = insertValidAccount('Test Account 9');
    acc.ShippingStateCode = 'ca';

    Test.startTest();
    update acc;
    Test.stopTest();

    Account result = [
      SELECT ShippingStateCode
      FROM Account
      WHERE Id = :acc.Id
    ];
    System.assertEquals(
      VALID_STATE_CODE,
      result.ShippingStateCode,
      'Lowercase "ca" should be normalized to "CA" on update'
    );
  }

  // -------------------------------------------------------------------
  // ShippingPostalCode format and range validation
  // -------------------------------------------------------------------

  @isTest
  static void testValidZipCodeBoundaries() {
    Account lowBound = buildAccount('Low Bound', VALID_STATE_CODE, '90001');
    Account highBound = buildAccount('High Bound', VALID_STATE_CODE, '96162');

    Test.startTest();
    insert new List<Account>{ lowBound, highBound };
    Test.stopTest();

    List<Account> results = [
      SELECT Id
      FROM Account
      WHERE Id IN :new List<Id>{ lowBound.Id, highBound.Id }
    ];
    System.assertEquals(
      2,
      results.size(),
      'Both boundary ZIP codes should be valid'
    );
  }

  @isTest
  static void testZipCodeOutOfRangeThrowsError() {
    Account acc = buildAccount('Test Account 3', VALID_STATE_CODE, '10001');

    Test.startTest();
    Database.SaveResult result = Database.insert(acc, false);
    Test.stopTest();

    System.assertEquals(
      false,
      result.isSuccess(),
      'Insert should fail for out-of-range ZIP'
    );
    System.assertEquals(
      Accounts.ZIP_ERROR,
      result.getErrors()[0].getMessage(),
      'Error message should match expected text'
    );
  }

  @isTest
  static void testZipCodeAboveRangeThrowsError() {
    Account acc = buildAccount('Test Account 3b', VALID_STATE_CODE, '96163');

    Test.startTest();
    Database.SaveResult result = Database.insert(acc, false);
    Test.stopTest();

    System.assertEquals(
      false,
      result.isSuccess(),
      'Insert should fail for a ZIP above the California range'
    );
    System.assertEquals(
      Accounts.ZIP_ERROR,
      result.getErrors()[0].getMessage(),
      'Error message should match expected text'
    );
  }

  @isTest
  static void testNonNumericZipThrowsError() {
    Account acc = buildAccount('Test Account 4', VALID_STATE_CODE, 'ABCDE');

    Test.startTest();
    Database.SaveResult result = Database.insert(acc, false);
    Test.stopTest();

    System.assertEquals(
      false,
      result.isSuccess(),
      'Insert should fail for non-numeric ZIP'
    );
    System.assertEquals(
      Accounts.ZIP_ERROR,
      result.getErrors()[0].getMessage(),
      'Error message should match expected text'
    );
  }

  @isTest
  static void testZipCodeWrongLengthThrowsError() {
    List<Account> accountsToInsert = new List<Account>{
      buildAccount('Test Account 4b', VALID_STATE_CODE, '9021'),
      buildAccount('Test Account 4c', VALID_STATE_CODE, '902100')
    };

    Test.startTest();
    List<Database.SaveResult> results = Database.insert(
      accountsToInsert,
      false
    );
    Test.stopTest();

    for (Database.SaveResult result : results) {
      System.assertEquals(
        false,
        result.isSuccess(),
        'Insert should fail for ZIP codes that are not exactly 5 digits'
      );
      System.assertEquals(
        Accounts.ZIP_ERROR,
        result.getErrors()[0].getMessage(),
        'Error message should match expected text'
      );
    }
  }

  @isTest
  static void testZipCodePlusFourThrowsError() {
    Account acc = buildAccount(
      'Test Account 4d',
      VALID_STATE_CODE,
      '90210-1234'
    );

    Test.startTest();
    Database.SaveResult result = Database.insert(acc, false);
    Test.stopTest();

    System.assertEquals(
      false,
      result.isSuccess(),
      'Insert should fail for ZIP+4 format'
    );
    System.assertEquals(
      Accounts.ZIP_ERROR,
      result.getErrors()[0].getMessage(),
      'Error message should match expected text'
    );
  }

  @isTest
  static void testZipCodeSurroundingWhitespaceIsTrimmed() {
    Account acc = buildAccount('Test Account 4e', VALID_STATE_CODE, ' 90210 ');

    Test.startTest();
    insert acc;
    Test.stopTest();

    Account result = [
      SELECT ShippingPostalCode
      FROM Account
      WHERE Id = :acc.Id
    ];
    System.assertEquals(
      '90210',
      result.ShippingPostalCode.trim(),
      'Surrounding whitespace in the ZIP code should be ignored'
    );
  }

  @isTest
  static void testZipCodeRevalidatedOnUpdate() {
    Account acc = insertValidAccount('Test Account 6b');
    acc.ShippingPostalCode = 'ABCDE';

    Test.startTest();
    Database.SaveResult result = Database.update(acc, false);
    Test.stopTest();

    System.assertEquals(
      false,
      result.isSuccess(),
      'Update should fail for an invalid ZIP'
    );
    System.assertEquals(
      Accounts.ZIP_ERROR,
      result.getErrors()[0].getMessage(),
      'Error message should match expected text'
    );
  }

  // -------------------------------------------------------------------
  // Blank ShippingStateCode / ShippingPostalCode handling
  // -------------------------------------------------------------------

  @isTest
  static void testBlankStateAndZipAreSkipped() {
    Account acc = buildAccount('Test Account 5', null, null);

    Test.startTest();
    insert acc;
    Test.stopTest();

    Account result = [SELECT Id FROM Account WHERE Id = :acc.Id];
    System.assertNotEquals(
      null,
      result.Id,
      'Account with blank state/zip should insert without error'
    );
  }

  @isTest
  static void testBlankStateWithValidZipIsAllowed() {
    Account acc = buildAccount('Test Account 5b', null, VALID_ZIP);

    Test.startTest();
    insert acc;
    Test.stopTest();

    Account result = [
      SELECT ShippingStateCode, ShippingPostalCode
      FROM Account
      WHERE Id = :acc.Id
    ];
    System.assertEquals(
      null,
      result.ShippingStateCode,
      'Blank state should be left blank'
    );
    System.assertEquals(
      VALID_ZIP,
      result.ShippingPostalCode,
      'Valid ZIP should be saved'
    );
  }

  @isTest
  static void testValidStateWithBlankZipIsAllowed() {
    Account acc = buildAccount('Test Account 5c', VALID_STATE_CODE, null);

    Test.startTest();
    insert acc;
    Test.stopTest();

    Account result = [
      SELECT ShippingStateCode, ShippingPostalCode
      FROM Account
      WHERE Id = :acc.Id
    ];
    System.assertEquals(
      VALID_STATE_CODE,
      result.ShippingStateCode,
      'Valid state should be saved'
    );
    System.assertEquals(
      null,
      result.ShippingPostalCode,
      'Blank ZIP should be left blank'
    );
  }

  @isTest
  static void testUpdateCanClearStateAndZip() {
    Account acc = insertValidAccount('Test Account 5d');
    acc.ShippingStateCode = null;
    acc.ShippingPostalCode = null;

    Test.startTest();
    Database.SaveResult result = Database.update(acc, false);
    Test.stopTest();

    System.assertEquals(
      true,
      result.isSuccess(),
      'Clearing state and ZIP should be allowed'
    );

    Account stored = [
      SELECT ShippingStateCode, ShippingPostalCode
      FROM Account
      WHERE Id = :acc.Id
    ];
    System.assertEquals(
      null,
      stored.ShippingStateCode,
      'State should be cleared'
    );
    System.assertEquals(
      null,
      stored.ShippingPostalCode,
      'ZIP should be cleared'
    );
  }

  @isTest
  static void testInvalidStateAndZipReportBothErrors() {
    Account acc = buildAccount('Test Account 11', 'NV', '10001');

    Test.startTest();
    Database.SaveResult result = Database.insert(acc, false);
    Test.stopTest();

    System.assertEquals(
      false,
      result.isSuccess(),
      'Insert should fail when both the state and ZIP are invalid'
    );

    Set<String> messages = new Set<String>();
    for (Database.Error error : result.getErrors()) {
      messages.add(error.getMessage());
    }
    System.assertEquals(
      2,
      messages.size(),
      'Both the state and ZIP errors should be reported'
    );
    System.assert(
      messages.contains(Accounts.STATE_ERROR),
      'State error should be reported'
    );
    System.assert(
      messages.contains(Accounts.ZIP_ERROR),
      'ZIP error should be reported'
    );
  }

  // -------------------------------------------------------------------
  // Update revalidates ShippingStateCode
  // -------------------------------------------------------------------

  @isTest
  static void testUpdateRevalidatesFields() {
    Account acc = insertValidAccount('Test Account 6');
    acc.ShippingStateCode = 'TX';

    Test.startTest();
    Database.SaveResult result = Database.update(acc, false);
    Test.stopTest();

    System.assertEquals(
      false,
      result.isSuccess(),
      'Update should fail for invalid state'
    );
    System.assertEquals(
      Accounts.STATE_ERROR,
      result.getErrors()[0].getMessage(),
      'Error message should match expected text'
    );
  }

  // -------------------------------------------------------------------
  // Deletion guard for Accounts with active (Ready) Bread Orders
  // -------------------------------------------------------------------

  @isTest
  static void testDeleteSuccess() {
    Account acc = insertValidAccount('Test Account 7');
    Bread__c bread = insertBread();
    insertBreadOrder(acc.Id, bread.Id, BreadOrders.STATUS_DELIVERED);

    Test.startTest();
    Database.DeleteResult result = Database.delete(acc, false);
    Test.stopTest();

    System.assertEquals(
      true,
      result.isSuccess(),
      'Delete should succeed when the only order is Delivered'
    );
    System.assertEquals(
      0,
      [SELECT COUNT() FROM Account WHERE Id = :acc.Id],
      'Account should be deleted'
    );
  }

  @isTest
  static void testDeleteWithNoOrdersSucceeds() {
    Account acc = insertValidAccount('Test Account 7b');

    Test.startTest();
    Database.DeleteResult result = Database.delete(acc, false);
    Test.stopTest();

    System.assertEquals(
      true,
      result.isSuccess(),
      'Delete should succeed for an Account with no Bread Orders'
    );
    System.assertEquals(
      0,
      [SELECT COUNT() FROM Account WHERE Id = :acc.Id],
      'Account should be deleted'
    );
  }

  @isTest
  static void testDeleteWithCancelledOrderSucceeds() {
    Account acc = insertValidAccount('Test Account 7c');
    Bread__c bread = insertBread();
    insertBreadOrder(acc.Id, bread.Id, BreadOrders.STATUS_CANCELLED);

    Test.startTest();
    Database.DeleteResult result = Database.delete(acc, false);
    Test.stopTest();

    System.assertEquals(
      true,
      result.isSuccess(),
      'Delete should succeed when the only order is Cancelled'
    );
    System.assertEquals(
      0,
      [SELECT COUNT() FROM Account WHERE Id = :acc.Id],
      'Account should be deleted'
    );
  }

  @isTest
  static void testDeleteThrowsError() {
    Account acc = insertValidAccount('Test Account 8');
    Bread__c bread = insertBread();
    insertBreadOrder(acc.Id, bread.Id, BreadOrders.STATUS_READY);

    Test.startTest();
    Database.DeleteResult result = Database.delete(acc, false);
    Test.stopTest();

    System.assertEquals(
      false,
      result.isSuccess(),
      'Delete should fail for an Account with one or more active Bread Orders'
    );
    System.assertEquals(
      Accounts.DELETE_ERROR,
      result.getErrors()[0].getMessage(),
      'Error message should match expected text'
    );
    System.assertEquals(
      1,
      [SELECT COUNT() FROM Account WHERE Id = :acc.Id],
      'Account should not be deleted'
    );
  }

  @isTest
  static void testDeleteWithReadyAndDeliveredOrdersThrowsError() {
    Account acc = insertValidAccount('Test Account 8b');
    Bread__c bread = insertBread();
    insertBreadOrder(acc.Id, bread.Id, BreadOrders.STATUS_DELIVERED);
    insertBreadOrder(acc.Id, bread.Id, BreadOrders.STATUS_READY);

    Test.startTest();
    Database.DeleteResult result = Database.delete(acc, false);
    Test.stopTest();

    System.assertEquals(
      false,
      result.isSuccess(),
      'A Ready order should block deletion even if other orders are Delivered'
    );
    System.assertEquals(
      Accounts.DELETE_ERROR,
      result.getErrors()[0].getMessage(),
      'Error message should match expected text'
    );
  }

  @isTest
  static void testBulkDeleteOnlyBlocksAccountsWithReadyOrders() {
    Account readyAccount = insertValidAccount('Test Account 12');
    Account deliveredAccount = insertValidAccount('Test Account 13');
    Account noOrderAccount = insertValidAccount('Test Account 14');

    Bread__c bread = insertBread();
    insertBreadOrder(readyAccount.Id, bread.Id, BreadOrders.STATUS_READY);
    insertBreadOrder(
      deliveredAccount.Id,
      bread.Id,
      BreadOrders.STATUS_DELIVERED
    );

    List<Account> accountsToDelete = new List<Account>{
      readyAccount,
      deliveredAccount,
      noOrderAccount
    };

    Test.startTest();
    List<Database.DeleteResult> results = Database.delete(
      accountsToDelete,
      false
    );
    Test.stopTest();

    System.assertEquals(
      false,
      results[0].isSuccess(),
      'Account with a Ready order should not be deleted'
    );
    System.assertEquals(
      Accounts.DELETE_ERROR,
      results[0].getErrors()[0].getMessage(),
      'Error message should match expected text'
    );
    System.assertEquals(
      true,
      results[1].isSuccess(),
      'Account with only a Delivered order should be deleted'
    );
    System.assertEquals(
      true,
      results[2].isSuccess(),
      'Account with no orders should be deleted'
    );

    System.assertEquals(
      1,
      [SELECT COUNT() FROM Account WHERE Id = :readyAccount.Id],
      'Blocked Account should still exist'
    );
    System.assertEquals(
      0,
      [SELECT COUNT() FROM Account WHERE Id = :deliveredAccount.Id],
      'Delivered-order Account should be deleted'
    );
    System.assertEquals(
      0,
      [SELECT COUNT() FROM Account WHERE Id = :noOrderAccount.Id],
      'No-order Account should be deleted'
    );
  }
}
