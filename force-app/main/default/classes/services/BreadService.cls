public with sharing class BreadService {
  
  public static List<Bread__c> getBreads() {
    return BreadsSelector.getBreads();
  }
}