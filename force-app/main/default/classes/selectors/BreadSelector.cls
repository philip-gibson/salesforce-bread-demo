public with sharing class BreadSelector {
  /**
   * Returns all Bread__c records.
   */
  public static List<Bread__c> getBreads() {
    return [
      SELECT Id, Name
      FROM Bread__c
      WITH USER_MODE
      ORDER BY Name
    ];
  }
}