List<Account> accs = [SELECT Id FROM Account WHERE ShippingLongitude != null AND Name != 'Salesforce Bakery'];
List<Bread__c> breads = [SELECT Id FROM Bread__c];

List<Bread_Order__c> orders = new List<Bread_Order__c>();

for (Account acc : accs) {
  // Shuffle a copy of the breads list so we can pick unique ones without repeats
  List<Bread__c> shuffledBreads = breads.clone();
  for (Integer i = shuffledBreads.size() - 1; i > 0; i--) {
    Integer swapIndex = Integer.valueOf(Math.random() * (i + 1));
    Bread__c temp = shuffledBreads[i];
    shuffledBreads[i] = shuffledBreads[swapIndex];
    shuffledBreads[swapIndex] = temp;
  }

  // Random number of orders per Account, between 2 and 5 inclusive
  Integer orderCount = Integer.valueOf(Math.random() * 4) + 2;
  for (Integer i = 0; i < orderCount; i++) {
    Integer randomQuantity = Integer.valueOf(Math.random() * 7) + 2; // 1-4
    Bread__c bread = shuffledBreads[i];

    orders.add(new Bread_Order__c(
      Account__c  = acc.Id,
      Bread__c    = bread.Id,
      Quantity__c = randomQuantity,
      Status__c   = 'Ready'
    ));
  }
}

insert orders;
System.debug('Inserted ' + orders.size() + ' Bread_Order__c records.');
