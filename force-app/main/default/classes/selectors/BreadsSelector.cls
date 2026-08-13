public with sharing class BreadsSelector {
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