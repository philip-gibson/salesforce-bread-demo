public class BreadOrderDTO {
  @AuraEnabled public Id accountId { get; set; }
  @AuraEnabled public Id breadId { get; set; }
  @AuraEnabled public Integer quantity { get; set; }
}
