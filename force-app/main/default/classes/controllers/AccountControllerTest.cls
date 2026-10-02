/**
 * Unit tests for the AccountController AuraEnabled controller, the server-side
 * API consumed by the Account Lightning Web Components:
 *   - createBreadOrder          (accountBreadOrderMaker)
 *   - setBreadOrdersToStatus    (accountBreadOrderPreparation)
 *   - getNewBreadOrders         (accountBreadOrderPreparation)
 *   - getBreadOrdersByAccountId (accountBreadOrders)
 *   - getBreads                 (accountBreadOrderMaker)
 *
 * Every controller method catches platform exceptions and re-throws them as an
 * AuraHandledException so that no internal error detail reaches the client. The
 * platform masks the message of an AuraHandledException ("Script-thrown
 * exception"), so the tests assert the exception type only.
 *
 * Test data notes:
 *   - State and Country picklists are enabled, so ShippingCountryCode must be
 *     set (using the ISO country code) before ShippingStateCode can be populated.
 *   - Accounts must ship to California with a valid Californian ZIP code, as
 *     the Accounts domain only accepts the state of California and rejects ZIP
 *     codes outside the 90001-96162 range.
 */
@isTest
private class AccountControllerTest {
  private static final String ACCOUNT_NAME = 'Test Account';
  private static final String BREAD_NAME = 'White Bread';
  private static final String BREAD_EXTERNAL_ID = 'White_Bread';
  private static final Decimal BREAD_UNIT_PRICE = 2.39;
  private static final String VALID_COUNTRY_CODE = 'US';
  private static final String VALID_STATE_CODE = 'CA';
  private static final String VALID_ZIP = '90210';
  private static final Integer ORDER_QUANTITY = 3;
  private static final String AURA_EXCEPTION_EXPECTED = 'Expected the controller to wrap the failure in an AuraHandledException';

  // -------------------------------------------------------------------
  // Test data helpers
  // -------------------------------------------------------------------

  private static Account insertCaliforniaAccount(String name) {
    Account acc = new Account(
      Name = name,
      ShippingCountryCode = VALID_COUNTRY_CODE,
      ShippingStateCode = VALID_STATE_CODE,
      ShippingPostalCode = VALID_ZIP
    );
    insert acc;
    return acc;
  }

  private static Bread__c insertBread(
    String name,
    String externalId,
    Decimal unitPrice
  ) {
    Bread__c bread = new Bread__c(
      Name = name,
      External_ID__c = externalId,
      Unit_Price__c = unitPrice
    );
    insert bread;
    return bread;
  }

  private static Bread_Order__c insertBreadOrder(
    Id accountId,
    Id breadId,
    String status,
    Integer quantity
  ) {
    Bread_Order__c breadOrder = new Bread_Order__c(
      Account__c = accountId,
      Bread__c = breadId,
      Status__c = status,
      Quantity__c = quantity
    );
    insert breadOrder;
    return breadOrder;
  }

  private static BreadOrderDTO buildBreadOrderDTO(
    Id accountId,
    Id breadId,
    Integer quantity
  ) {
    BreadOrderDTO dto = new BreadOrderDTO();
    dto.accountId = accountId;
    dto.breadId = breadId;
    dto.quantity = quantity;
    return dto;
  }

  /**
   * A user whose profile grants no access to Bread__c or Bread_Order__c, used
   * to prove that user-mode query failures are surfaced as an
   * AuraHandledException by the controller.
   */
  private static User insertRestrictedUser() {
    Profile minimalAccessProfile = [
      SELECT Id
      FROM Profile
      WHERE Name = 'Minimum Access - Salesforce'
      LIMIT 1
    ];

    User restrictedUser = new User(
      ProfileId = minimalAccessProfile.Id,
      LastName = 'Restricted',
      Email = 'restricted.user@example.com',
      Username = 'restricted' + DateTime.now().getTime() + '@example.com',
      Alias = 'restrct',
      TimeZoneSidKey = 'America/Los_Angeles',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US'
    );
    insert restrictedUser;
    return restrictedUser;
  }

  // -------------------------------------------------------------------
  // createBreadOrder
  // -------------------------------------------------------------------

  @isTest
  static void testCreateBreadOrder() {
    Account acc = insertCaliforniaAccount(ACCOUNT_NAME);
    Bread__c bread = insertBread(
      BREAD_NAME,
      BREAD_EXTERNAL_ID,
      BREAD_UNIT_PRICE
    );

    Test.startTest();
    AccountController.createBreadOrder(
      buildBreadOrderDTO(acc.Id, bread.Id, ORDER_QUANTITY)
    );
    Test.stopTest();

    List<Bread_Order__c> createdOrders = [
      SELECT
        Account__c,
        Bread__c,
        Quantity__c,
        Status__c,
        Unit_Price__c,
        Total__c
      FROM Bread_Order__c
    ];
    System.assertEquals(
      1,
      createdOrders.size(),
      'One Bread Order should be created'
    );
    System.assertEquals(
      acc.Id,
      createdOrders[0].Account__c,
      'Order should belong to the Account from the DTO'
    );
    System.assertEquals(
      bread.Id,
      createdOrders[0].Bread__c,
      'Order should reference the Bread from the DTO'
    );
    System.assertEquals(
      ORDER_QUANTITY,
      createdOrders[0].Quantity__c,
      'Quantity should come from the DTO'
    );
    System.assertEquals(
      BreadOrders.STATUS_NEW,
      createdOrders[0].Status__c,
      'New Bread Orders default to the New status'
    );
    System.assertEquals(
      BREAD_UNIT_PRICE,
      createdOrders[0].Unit_Price__c,
      'Unit Price should be copied from the Bread'
    );
    System.assertEquals(
      ORDER_QUANTITY * BREAD_UNIT_PRICE,
      createdOrders[0].Total__c,
      'Total should be Quantity x Unit Price'
    );
  }

  @isTest
  static void testCreateBreadOrderFromAuraJsonPayload() {
    Account acc = insertCaliforniaAccount(ACCOUNT_NAME);
    Bread__c bread = insertBread(
      BREAD_NAME,
      BREAD_EXTERNAL_ID,
      BREAD_UNIT_PRICE
    );

    // Lightning serializes the BreadOrderDTO parameter as JSON, so the DTO must
    // be deserializable using its no-arg constructor.
    String payload =
      '{"accountId":"' +
      acc.Id +
      '","breadId":"' +
      bread.Id +
      '","quantity":4}';
    BreadOrderDTO dto = (BreadOrderDTO) JSON.deserialize(
      payload,
      BreadOrderDTO.class
    );

    Test.startTest();
    AccountController.createBreadOrder(dto);
    Test.stopTest();

    Bread_Order__c breadOrder = [
      SELECT Account__c, Bread__c, Quantity__c, Total__c
      FROM Bread_Order__c
    ];
    System.assertEquals(
      acc.Id,
      breadOrder.Account__c,
      'Account should be deserialized from the JSON payload'
    );
    System.assertEquals(
      bread.Id,
      breadOrder.Bread__c,
      'Bread should be deserialized from the JSON payload'
    );
    System.assertEquals(
      4,
      breadOrder.Quantity__c,
      'Quantity should be deserialized from the JSON payload'
    );
    System.assertEquals(
      4 * BREAD_UNIT_PRICE,
      breadOrder.Total__c,
      'Total should be Quantity x Unit Price'
    );
  }

  @isTest
  static void testCreateBreadOrderWithNullDtoThrowsAuraHandledException() {
    Boolean threw = false;

    Test.startTest();
    try {
      AccountController.createBreadOrder(null);
    } catch (AuraHandledException e) {
      threw = true;
    }
    Test.stopTest();

    System.assertEquals(true, threw, AURA_EXCEPTION_EXPECTED);
  }

  @isTest
  static void testCreateBreadOrderWithoutBreadThrowsAuraHandledException() {
    Account acc = insertCaliforniaAccount(ACCOUNT_NAME);
    Boolean threw = false;

    Test.startTest();
    try {
      AccountController.createBreadOrder(
        buildBreadOrderDTO(acc.Id, null, ORDER_QUANTITY)
      );
    } catch (AuraHandledException e) {
      threw = true;
    }
    Test.stopTest();

    System.assertEquals(true, threw, AURA_EXCEPTION_EXPECTED);
    System.assertEquals(
      0,
      [SELECT COUNT() FROM Bread_Order__c],
      'No order should be created when the Bread is missing'
    );
  }

  @isTest
  static void testCreateBreadOrderWithUnknownBreadThrowsAuraHandledException() {
    Account acc = insertCaliforniaAccount(ACCOUNT_NAME);
    BreadOrderDTO dto = buildBreadOrderDTO(
      acc.Id,
      fflib_IDGenerator.generate(Bread__c.SObjectType),
      ORDER_QUANTITY
    );
    Boolean threw = false;

    Test.startTest();
    try {
      AccountController.createBreadOrder(dto);
    } catch (AuraHandledException e) {
      threw = true;
    }
    Test.stopTest();

    System.assertEquals(true, threw, AURA_EXCEPTION_EXPECTED);
    System.assertEquals(
      0,
      [SELECT COUNT() FROM Bread_Order__c],
      'No order should be created when the Bread does not exist'
    );
  }

  // -------------------------------------------------------------------
  // setBreadOrdersToStatus
  // -------------------------------------------------------------------

  @isTest
  static void testSetBreadOrdersToStatusReady() {
    Account acc = insertCaliforniaAccount(ACCOUNT_NAME);
    Bread__c bread = insertBread(
      BREAD_NAME,
      BREAD_EXTERNAL_ID,
      BREAD_UNIT_PRICE
    );
    Bread_Order__c breadOrder = insertBreadOrder(
      acc.Id,
      bread.Id,
      BreadOrders.STATUS_NEW,
      ORDER_QUANTITY
    );

    Test.startTest();
    AccountController.setBreadOrdersToStatus(
      new List<Id>{ breadOrder.Id },
      BreadOrders.STATUS_READY
    );
    Test.stopTest();

    System.assertEquals(
      BreadOrders.STATUS_READY,
      [SELECT Status__c FROM Bread_Order__c WHERE Id = :breadOrder.Id]
      .Status__c,
      'Order should be set to Ready'
    );
  }

  @isTest
  static void testSetBreadOrdersToStatusCancelled() {
    Account acc = insertCaliforniaAccount(ACCOUNT_NAME);
    Bread__c bread = insertBread(
      BREAD_NAME,
      BREAD_EXTERNAL_ID,
      BREAD_UNIT_PRICE
    );
    Bread_Order__c breadOrder = insertBreadOrder(
      acc.Id,
      bread.Id,
      BreadOrders.STATUS_NEW,
      ORDER_QUANTITY
    );

    Test.startTest();
    AccountController.setBreadOrdersToStatus(
      new List<Id>{ breadOrder.Id },
      BreadOrders.STATUS_CANCELLED
    );
    Test.stopTest();

    System.assertEquals(
      BreadOrders.STATUS_CANCELLED,
      [SELECT Status__c FROM Bread_Order__c WHERE Id = :breadOrder.Id]
      .Status__c,
      'Order should be set to Cancelled'
    );
  }

  @isTest
  static void testSetBreadOrdersToStatusBulk() {
    Account acc = insertCaliforniaAccount(ACCOUNT_NAME);
    Bread__c bread = insertBread(
      BREAD_NAME,
      BREAD_EXTERNAL_ID,
      BREAD_UNIT_PRICE
    );

    List<Id> breadOrderIds = new List<Id>();
    for (Integer i = 0; i < 3; i++) {
      breadOrderIds.add(
        insertBreadOrder(
            acc.Id,
            bread.Id,
            BreadOrders.STATUS_NEW,
            ORDER_QUANTITY
          )
          .Id
      );
    }

    Test.startTest();
    AccountController.setBreadOrdersToStatus(
      breadOrderIds,
      BreadOrders.STATUS_READY
    );
    Test.stopTest();

    System.assertEquals(
      3,
      [
        SELECT COUNT()
        FROM Bread_Order__c
        WHERE Id IN :breadOrderIds AND Status__c = :BreadOrders.STATUS_READY
      ],
      'All orders in the list should be set to Ready'
    );
  }

  @isTest
  static void testSetBreadOrdersToStatusIgnoresUnsupportedStatus() {
    Account acc = insertCaliforniaAccount(ACCOUNT_NAME);
    Bread__c bread = insertBread(
      BREAD_NAME,
      BREAD_EXTERNAL_ID,
      BREAD_UNIT_PRICE
    );
    Bread_Order__c breadOrder = insertBreadOrder(
      acc.Id,
      bread.Id,
      BreadOrders.STATUS_NEW,
      ORDER_QUANTITY
    );

    Test.startTest();
    AccountController.setBreadOrdersToStatus(
      new List<Id>{ breadOrder.Id },
      BreadOrders.STATUS_DELIVERED
    );
    AccountController.setBreadOrdersToStatus(
      new List<Id>{ breadOrder.Id },
      BreadOrders.STATUS_NEW
    );
    Test.stopTest();

    System.assertEquals(
      BreadOrders.STATUS_NEW,
      [SELECT Status__c FROM Bread_Order__c WHERE Id = :breadOrder.Id]
      .Status__c,
      'Only Ready and Cancelled are applied, so other statuses leave the order unchanged'
    );
  }

  @isTest
  static void testSetBreadOrdersToStatusIgnoresNullStatus() {
    Account acc = insertCaliforniaAccount(ACCOUNT_NAME);
    Bread__c bread = insertBread(
      BREAD_NAME,
      BREAD_EXTERNAL_ID,
      BREAD_UNIT_PRICE
    );
    Bread_Order__c breadOrder = insertBreadOrder(
      acc.Id,
      bread.Id,
      BreadOrders.STATUS_NEW,
      ORDER_QUANTITY
    );

    Test.startTest();
    AccountController.setBreadOrdersToStatus(
      new List<Id>{ breadOrder.Id },
      null
    );
    Test.stopTest();

    System.assertEquals(
      BreadOrders.STATUS_NEW,
      [SELECT Status__c FROM Bread_Order__c WHERE Id = :breadOrder.Id]
      .Status__c,
      'A null status leaves the order unchanged'
    );
  }

  @isTest
  static void testSetBreadOrdersToStatusWithEmptyListIsNoOp() {
    Account acc = insertCaliforniaAccount(ACCOUNT_NAME);
    Bread__c bread = insertBread(
      BREAD_NAME,
      BREAD_EXTERNAL_ID,
      BREAD_UNIT_PRICE
    );
    Bread_Order__c breadOrder = insertBreadOrder(
      acc.Id,
      bread.Id,
      BreadOrders.STATUS_NEW,
      ORDER_QUANTITY
    );

    Test.startTest();
    AccountController.setBreadOrdersToStatus(
      new List<Id>(),
      BreadOrders.STATUS_READY
    );
    Test.stopTest();

    System.assertEquals(
      BreadOrders.STATUS_NEW,
      [SELECT Status__c FROM Bread_Order__c WHERE Id = :breadOrder.Id]
      .Status__c,
      'An empty Id list leaves every order unchanged'
    );
  }

  @isTest
  static void testSetBreadOrdersToStatusWithNullListThrowsAuraHandledException() {
    Boolean threw = false;

    Test.startTest();
    try {
      AccountController.setBreadOrdersToStatus(null, BreadOrders.STATUS_READY);
    } catch (AuraHandledException e) {
      threw = true;
    }
    Test.stopTest();

    System.assertEquals(true, threw, AURA_EXCEPTION_EXPECTED);
  }

  @isTest
  static void testSetBreadOrdersToStatusWithUnknownOrderThrowsAuraHandledException() {
    // A well-formed Id for a Bread Order that does not exist.
    List<Id> unknownIds = new List<Id>{
      fflib_IDGenerator.generate(Bread_Order__c.SObjectType)
    };
    Boolean threw = false;

    Test.startTest();
    try {
      AccountController.setBreadOrdersToStatus(
        unknownIds,
        BreadOrders.STATUS_READY
      );
    } catch (AuraHandledException e) {
      threw = true;
    }
    Test.stopTest();

    System.assertEquals(true, threw, AURA_EXCEPTION_EXPECTED);
  }

  // -------------------------------------------------------------------
  // getNewBreadOrders
  // -------------------------------------------------------------------

  @isTest
  static void testGetNewBreadOrdersReturnsOnlyNewOrdersOrderedByBreadName() {
    Account acc = insertCaliforniaAccount(ACCOUNT_NAME);
    Bread__c ryeBread = insertBread('Rye Bread', 'Rye_Bread', 3.00);
    Bread__c whiteBread = insertBread(
      BREAD_NAME,
      BREAD_EXTERNAL_ID,
      BREAD_UNIT_PRICE
    );

    insertBreadOrder(acc.Id, ryeBread.Id, BreadOrders.STATUS_NEW, 1);
    insertBreadOrder(acc.Id, whiteBread.Id, BreadOrders.STATUS_NEW, 2);
    insertBreadOrder(acc.Id, whiteBread.Id, BreadOrders.STATUS_READY, 3);
    insertBreadOrder(acc.Id, ryeBread.Id, BreadOrders.STATUS_DELIVERED, 4);
    insertBreadOrder(acc.Id, whiteBread.Id, BreadOrders.STATUS_CANCELLED, 5);

    Test.startTest();
    List<Bread_Order__c> newBreadOrders = AccountController.getNewBreadOrders(
      acc.Id
    );
    Test.stopTest();

    System.assertEquals(
      2,
      newBreadOrders.size(),
      'Only the New orders of the Account should be returned'
    );
    System.assertEquals(
      'Rye Bread',
      newBreadOrders[0].Bread__r.Name,
      'Orders should be ordered by Bread name'
    );
    System.assertEquals(
      'White Bread',
      newBreadOrders[1].Bread__r.Name,
      'Orders should be ordered by Bread name'
    );
    System.assertEquals(
      BreadOrders.STATUS_NEW,
      newBreadOrders[0].Status__c,
      'Every returned order should be New'
    );
    System.assertEquals(
      ACCOUNT_NAME,
      newBreadOrders[0].Account__r.Name,
      'Account name should be returned for the order'
    );
    System.assertEquals(
      3.00,
      newBreadOrders[0].Total__c,
      'Total should be returned for the order'
    );
  }

  @isTest
  static void testGetNewBreadOrdersIsScopedToAccount() {
    Account acc = insertCaliforniaAccount('Test Account 1');
    Account otherAcc = insertCaliforniaAccount('Test Account 2');
    Bread__c bread = insertBread(
      BREAD_NAME,
      BREAD_EXTERNAL_ID,
      BREAD_UNIT_PRICE
    );
    Bread_Order__c breadOrder = insertBreadOrder(
      acc.Id,
      bread.Id,
      BreadOrders.STATUS_NEW,
      ORDER_QUANTITY
    );
    insertBreadOrder(
      otherAcc.Id,
      bread.Id,
      BreadOrders.STATUS_NEW,
      ORDER_QUANTITY
    );

    Test.startTest();
    List<Bread_Order__c> newBreadOrders = AccountController.getNewBreadOrders(
      acc.Id
    );
    Test.stopTest();

    System.assertEquals(
      1,
      newBreadOrders.size(),
      'Only the New orders of the given Account should be returned'
    );
    System.assertEquals(
      breadOrder.Id,
      newBreadOrders[0].Id,
      'The other Account order should not be returned'
    );
  }

  @isTest
  static void testGetNewBreadOrdersReturnsEmptyForAccountWithoutNewOrders() {
    Account acc = insertCaliforniaAccount(ACCOUNT_NAME);
    Bread__c bread = insertBread(
      BREAD_NAME,
      BREAD_EXTERNAL_ID,
      BREAD_UNIT_PRICE
    );
    insertBreadOrder(acc.Id, bread.Id, BreadOrders.STATUS_DELIVERED, 1);
    insertBreadOrder(acc.Id, bread.Id, BreadOrders.STATUS_CANCELLED, 2);

    Test.startTest();
    List<Bread_Order__c> newBreadOrders = AccountController.getNewBreadOrders(
      acc.Id
    );
    Test.stopTest();

    System.assertEquals(
      0,
      newBreadOrders.size(),
      'An Account with no New orders returns an empty list'
    );
  }

  @isTest
  static void testGetNewBreadOrdersWithNullAccountReturnsEmpty() {
    Account acc = insertCaliforniaAccount(ACCOUNT_NAME);
    Bread__c bread = insertBread(
      BREAD_NAME,
      BREAD_EXTERNAL_ID,
      BREAD_UNIT_PRICE
    );
    insertBreadOrder(acc.Id, bread.Id, BreadOrders.STATUS_NEW, ORDER_QUANTITY);

    Test.startTest();
    List<Bread_Order__c> newBreadOrders = AccountController.getNewBreadOrders(
      null
    );
    Test.stopTest();

    System.assertEquals(
      0,
      newBreadOrders.size(),
      'A null Account Id returns no orders'
    );
  }

  @isTest
  static void testGetNewBreadOrdersWithoutReadAccessThrowsAuraHandledException() {
    Account acc = insertCaliforniaAccount(ACCOUNT_NAME);
    User restrictedUser = insertRestrictedUser();
    Boolean threw = false;

    System.runAs(restrictedUser) {
      Test.startTest();
      try {
        AccountController.getNewBreadOrders(acc.Id);
      } catch (AuraHandledException e) {
        threw = true;
      }
      Test.stopTest();
    }

    System.assertEquals(true, threw, AURA_EXCEPTION_EXPECTED);
  }

  // -------------------------------------------------------------------
  // getBreadOrdersByAccountId
  // -------------------------------------------------------------------

  @isTest
  static void testGetBreadOrdersByAccountIdReturnsAllOrdersNewestFirst() {
    Account acc = insertCaliforniaAccount(ACCOUNT_NAME);
    Bread__c bread = insertBread(
      BREAD_NAME,
      BREAD_EXTERNAL_ID,
      BREAD_UNIT_PRICE
    );
    Bread_Order__c olderOrder = insertBreadOrder(
      acc.Id,
      bread.Id,
      BreadOrders.STATUS_DELIVERED,
      1
    );
    Bread_Order__c newerOrder = insertBreadOrder(
      acc.Id,
      bread.Id,
      BreadOrders.STATUS_CANCELLED,
      2
    );

    // Orders created in the same transaction share a CreatedDate, so stamp
    // distinct values to make the "newest first" ordering deterministic.
    Test.setCreatedDate(
      olderOrder.Id,
      DateTime.newInstance(2020, 1, 1, 12, 0, 0)
    );
    Test.setCreatedDate(
      newerOrder.Id,
      DateTime.newInstance(2020, 1, 2, 12, 0, 0)
    );

    Test.startTest();
    List<Bread_Order__c> returnedOrders = AccountController.getBreadOrdersByAccountId(
      acc.Id
    );
    Test.stopTest();

    System.assertEquals(
      2,
      returnedOrders.size(),
      'Every Bread Order of the Account should be returned'
    );
    System.assertEquals(
      newerOrder.Id,
      returnedOrders[0].Id,
      'The newest order should be returned first'
    );
    System.assertEquals(
      olderOrder.Id,
      returnedOrders[1].Id,
      'The oldest order should be returned last'
    );
    System.assertEquals(
      BREAD_NAME,
      returnedOrders[0].Bread__r.Name,
      'Bread name should be returned for the order'
    );
    System.assertEquals(
      BreadOrders.STATUS_CANCELLED,
      returnedOrders[0].Status__c,
      'Status should be returned for the order'
    );
    System.assertEquals(
      2,
      returnedOrders[0].Quantity__c,
      'Quantity should be returned for the order'
    );
    System.assertEquals(
      2 * BREAD_UNIT_PRICE,
      returnedOrders[0].Total__c,
      'Total should be returned for the order'
    );
  }

  @isTest
  static void testGetBreadOrdersByAccountIdIsScopedToAccount() {
    Account acc = insertCaliforniaAccount('Test Account 1');
    Account otherAcc = insertCaliforniaAccount('Test Account 2');
    Bread__c bread = insertBread(
      BREAD_NAME,
      BREAD_EXTERNAL_ID,
      BREAD_UNIT_PRICE
    );
    Bread_Order__c breadOrder = insertBreadOrder(
      acc.Id,
      bread.Id,
      BreadOrders.STATUS_NEW,
      ORDER_QUANTITY
    );
    insertBreadOrder(
      otherAcc.Id,
      bread.Id,
      BreadOrders.STATUS_NEW,
      ORDER_QUANTITY
    );

    Test.startTest();
    List<Bread_Order__c> returnedOrders = AccountController.getBreadOrdersByAccountId(
      acc.Id
    );
    Test.stopTest();

    System.assertEquals(
      1,
      returnedOrders.size(),
      'Only the Bread Orders of the given Account should be returned'
    );
    System.assertEquals(
      breadOrder.Id,
      returnedOrders[0].Id,
      'The other Account order should not be returned'
    );
  }

  @isTest
  static void testGetBreadOrdersByAccountIdReturnsEmptyForAccountWithoutOrders() {
    Account acc = insertCaliforniaAccount(ACCOUNT_NAME);

    Test.startTest();
    List<Bread_Order__c> returnedOrders = AccountController.getBreadOrdersByAccountId(
      acc.Id
    );
    Test.stopTest();

    System.assertEquals(
      0,
      returnedOrders.size(),
      'An Account without Bread Orders returns an empty list'
    );
  }

  @isTest
  static void testGetBreadOrdersByAccountIdWithNullReturnsEmpty() {
    Account acc = insertCaliforniaAccount(ACCOUNT_NAME);
    Bread__c bread = insertBread(
      BREAD_NAME,
      BREAD_EXTERNAL_ID,
      BREAD_UNIT_PRICE
    );
    insertBreadOrder(acc.Id, bread.Id, BreadOrders.STATUS_NEW, ORDER_QUANTITY);

    Test.startTest();
    List<Bread_Order__c> returnedOrders = AccountController.getBreadOrdersByAccountId(
      null
    );
    Test.stopTest();

    System.assertEquals(
      0,
      returnedOrders.size(),
      'A null Account Id returns no orders'
    );
  }

  @isTest
  static void testGetBreadOrdersByAccountIdWithoutReadAccessThrowsAuraHandledException() {
    Account acc = insertCaliforniaAccount(ACCOUNT_NAME);
    User restrictedUser = insertRestrictedUser();
    Boolean threw = false;

    System.runAs(restrictedUser) {
      Test.startTest();
      try {
        AccountController.getBreadOrdersByAccountId(acc.Id);
      } catch (AuraHandledException e) {
        threw = true;
      }
      Test.stopTest();
    }

    System.assertEquals(true, threw, AURA_EXCEPTION_EXPECTED);
  }

  // -------------------------------------------------------------------
  // getBreads
  // -------------------------------------------------------------------

  @isTest
  static void testGetBreadsReturnsAllBreadsOrderedByName() {
    insertBread(BREAD_NAME, BREAD_EXTERNAL_ID, BREAD_UNIT_PRICE);
    insertBread('Baguette', 'Baguette', 1.50);

    Test.startTest();
    List<Bread__c> breads = AccountController.getBreads();
    Test.stopTest();

    System.assertEquals(2, breads.size(), 'All Breads should be returned');
    System.assertEquals(
      'Baguette',
      breads[0].Name,
      'Breads should be ordered by Name'
    );
    System.assertEquals(
      'White Bread',
      breads[1].Name,
      'Breads should be ordered by Name'
    );
    System.assertNotEquals(
      null,
      breads[0].Id,
      'The Bread Id should be returned'
    );
  }

  @isTest
  static void testGetBreadsReturnsEmptyWhenThereAreNoBreads() {
    Test.startTest();
    List<Bread__c> breads = AccountController.getBreads();
    Test.stopTest();

    System.assertEquals(
      0,
      breads.size(),
      'An empty org returns an empty Bread list'
    );
  }

  @isTest
  static void testGetBreadsWithoutReadAccessThrowsAuraHandledException() {
    insertBread(BREAD_NAME, BREAD_EXTERNAL_ID, BREAD_UNIT_PRICE);
    User restrictedUser = insertRestrictedUser();
    Boolean threw = false;

    System.runAs(restrictedUser) {
      Test.startTest();
      try {
        AccountController.getBreads();
      } catch (AuraHandledException e) {
        threw = true;
      }
      Test.stopTest();
    }

    System.assertEquals(true, threw, AURA_EXCEPTION_EXPECTED);
  }
}
