public class BreadOrderDTO {
  @AuraEnabled public Id accountId { get; set; }
  @AuraEnabled public String accountName { get; set; }
  @AuraEnabled public Id breadId { get; set; }
  @AuraEnabled public String breadName { get; set; }
  @AuraEnabled public Id id { get; set; }
  @AuraEnabled public Decimal total { get; set; }
  @AuraEnabled public Integer quantity { get; set; }

  /**
   * No-arg constructor required so the platform can deserialize an inbound
   * BreadOrderDTO from LWC/JSON (e.g. AccountController.createBreadOrder).
   * Declaring the parameterized constructor below removes the implicit one.
   */
  public BreadOrderDTO() {}

  public BreadOrderDTO(Bread_Order__c bo) {
    this.id = bo.Id;
    this.accountId = bo.Account__c;
    this.accountName = bo.Account__r.Name;
    this.breadName = bo.Bread__r.Name;
    this.total = bo.Total__c;
    this.quantity = (bo.Quantity__c != null) ? bo.Quantity__c.intValue() : null;
  }
}
