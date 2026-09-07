@isTest
private class AccountsTest {

  @isTest
  static void testLowercaseCaliforniaIsCapitalized() {
    Account acc = new Account(
      Name = 'Test Account 1',
      ShippingState = 'california',
      ShippingPostalCode = '90210'
    );

    Test.startTest();
    insert acc;
    Test.stopTest();

    Account result = [SELECT ShippingState FROM Account WHERE Id = :acc.Id];
    System.assertEquals('California', result.ShippingState, 'Lowercase "california" should be auto-capitalized');
  }

  @isTest
  static void testMixedCaseCaliforniaIsCapitalized() {
    Account acc = new Account(
      Name = 'Test Account 1b',
      ShippingState = 'CaLiFoRnIa',
      ShippingPostalCode = '90210'
    );

    Test.startTest();
    insert acc;
    Test.stopTest();

    Account result = [SELECT ShippingState FROM Account WHERE Id = :acc.Id];
    System.assertEquals('California', result.ShippingState, 'Mixed-case "california" should be auto-capitalized');
  }

  @isTest
  static void testInvalidStateThrowsError() {
    Account acc = new Account(
      Name = 'Test Account 2',
      ShippingState = 'Nevada',
      ShippingPostalCode = '90210'
    );

    Test.startTest();
    Database.SaveResult result = Database.insert(acc, false);
    Test.stopTest();

    System.assertEquals(false, result.isSuccess(), 'Insert should fail for non-California state');
    System.assertEquals(
      Accounts.STATE_ERROR,
      result.getErrors()[0].getMessage(),
      'Error message should match expected text'
    );
  }

  @isTest
  static void testValidZipCodeBoundaries() {
    Account lowBound = new Account(
      Name = 'Low Bound',
      ShippingState = 'California',
      ShippingPostalCode = '90001'
    );
    Account highBound = new Account(
      Name = 'High Bound',
      ShippingState = 'California',
      ShippingPostalCode = '96162'
    );

    Test.startTest();
    insert new List<Account>{ lowBound, highBound };
    Test.stopTest();

    List<Account> results = [SELECT Id FROM Account WHERE Id IN :new List<Id>{ lowBound.Id, highBound.Id }];
    System.assertEquals(2, results.size(), 'Both boundary ZIP codes should be valid');
  }

  @isTest
  static void testZipCodeOutOfRangeThrowsError() {
    Account acc = new Account(
      Name = 'Test Account 3',
      ShippingState = 'California',
      ShippingPostalCode = '10001'
    );

    Test.startTest();
    Database.SaveResult result = Database.insert(acc, false);
    Test.stopTest();

    System.assertEquals(false, result.isSuccess(), 'Insert should fail for out-of-range ZIP');
    System.assertEquals(
      Accounts.ZIP_ERROR,
      result.getErrors()[0].getMessage(),
      'Error message should match expected text'
    );
  }

  @isTest
  static void testNonNumericZipThrowsError() {
    Account acc = new Account(
      Name = 'Test Account 4',
      ShippingState = 'California',
      ShippingPostalCode = 'ABCDE'
    );

    Test.startTest();
    Database.SaveResult result = Database.insert(acc, false);
    Test.stopTest();

    System.assertEquals(false, result.isSuccess(), 'Insert should fail for non-numeric ZIP');
    System.assertEquals(
      Accounts.ZIP_ERROR,
      result.getErrors()[0].getMessage(),
      'Error message should match expected text'
    );
  }

  @isTest
  static void testBlankStateAndZipAreSkipped() {
    Account acc = new Account(Name = 'Test Account 5');

    Test.startTest();
    insert acc;
    Test.stopTest();

    Account result = [SELECT Id FROM Account WHERE Id = :acc.Id];
    System.assertNotEquals(null, result.Id, 'Account with blank state/zip should insert without error');
  }

  @isTest
  static void testUpdateRevalidatesFields() {
    Account acc = new Account(
      Name = 'Test Account 6',
      ShippingState = 'California',
      ShippingPostalCode = '90210'
    );
    insert acc;

    acc.ShippingState = 'texas';

    Test.startTest();
    Database.SaveResult result = Database.update(acc, false);
    Test.stopTest();

    System.assertEquals(false, result.isSuccess(), 'Update should fail for invalid state');
  }

  @isTest
  static void testDeleteSuccess() {
    Account acc = new Account(
      Name = 'Test Account 7',
      ShippingState = 'California',
      ShippingPostalCode = '90210'
    );
    insert acc;

    Bread__c bread = new Bread__c(
      Name = 'White Bread',
      External_ID__c = 'White_Bread',
      Unit_Price__c = 2.39
    );
    insert bread;

    Bread_Order__c bo = new Bread_Order__c(
      Account__c = acc.Id,
      Bread__c = bread.Id,
      Status__c = BreadOrders.STATUS_DELIVERED,
      Quantity__c = 3
    );
    insert bo;

    Test.startTest();
    Database.DeleteResult result = Database.delete(acc, false);
    Test.stopTest();

    System.assertEquals(true, result.isSuccess(), 'Delete should succeed for account');
    Integer count = [SELECT count() FROM Account WHERE Id = :acc.Id];
    System.assertEquals(0, count, 'Account should be deleted');
  }

  @isTest
  static void testDeleteThrowsError() {
    Account acc = new Account(
      Name = 'Test Account 8',
      ShippingState = 'California',
      ShippingPostalCode = '90210'
    );
    insert acc;

    Bread__c bread = new Bread__c(
      Name = 'White Bread',
      External_ID__c = 'White_Bread',
      Unit_Price__c = 2.39
    );
    insert bread;

    Bread_Order__c bo = new Bread_Order__c(
      Account__c = acc.Id,
      Bread__c = bread.Id,
      Status__c = BreadOrders.STATUS_READY,
      Quantity__c = 3
    );
    insert bo;

    Test.startTest();
    Database.DeleteResult result = Database.delete(acc, false);
    Test.stopTest();

    System.assertEquals(false, result.isSuccess(), 'Delete should fail for account with one or more active Bread Orders');
    System.assertEquals(
      Accounts.DELETE_ERROR,
      result.getErrors()[0].getMessage(),
      'Error message should match expected text'
    );
  }
}
