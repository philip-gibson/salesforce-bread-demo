public with sharing class BreadsService {
  
  public static List<Bread__c> getBreads() {
    return BreadsSelector.getBreads();
  }
}