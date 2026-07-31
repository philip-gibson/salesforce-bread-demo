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
        System.assertEquals('California', result.ShippingState,
            'Lowercase "california" should be auto-capitalized');
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
        System.assertEquals('California', result.ShippingState,
            'Mixed-case "california" should be auto-capitalized');
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
            'State must be \'California\'',
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
            'In the State of California, ZIP codes generally range from 90001 to 96162',
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
            'In the State of California, ZIP codes generally range from 90001 to 96162',
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
}
