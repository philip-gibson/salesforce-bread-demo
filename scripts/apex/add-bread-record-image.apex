List<String> bread_External_Ids = new List<String>{
  'White_Bread',
  'Wholewheat_Bread',
  'Rye_Bread',
  'Sourdough_Bread',
  'Multigrain_Bread',
  'Baguette',
  'Ciabatta',
  'Pumpernickel_Bread',
  'Brioche',
  'Flatbread',
  'Bagel',
  'Focaccia',
  'Soda_Bread'
};

// Step 1: Query bread records and return the External ID
Map<String, Id> externalIdToRecordId = new Map<String, Id>();
for (Bread__c bread : [SELECT External_ID__c
                       FROM Bread__c
                       WHERE External_ID__c IN :bread_External_Ids]) {
  externalIdToRecordId.put(bread.External_ID__c, bread.Id);
}

// Step 2: Query the static resources where Name matches the bread record External ID
Map<String, StaticResource> resourcesByName = new Map<String, StaticResource>();
for (StaticResource sr : [SELECT Name, Body, ContentType
                          FROM StaticResource
                          WHERE Name IN :bread_External_Ids]) {
  resourcesByName.put(sr.Name, sr);
}

// Step 3: Build ContentVersions, matching static resource Name to bread record External ID
List<ContentVersion> versionsToInsert = new List<ContentVersion>();
for (String breadName : resourcesByName.keySet()) {
  Id recordId = externalIdToRecordId.get(breadName);
  if (recordId != null) {
    StaticResource sr = resourcesByName.get(breadName);
    versionsToInsert.add(new ContentVersion(
      Title = breadName,
      PathOnClient = breadName + '.png',
      VersionData = sr.Body,
      FirstPublishLocationId = recordId
    ));
  }
}

insert versionsToInsert;
System.debug('Inserted ' + versionsToInsert.size() + ' ContentVersions.');
