public with sharing class BreadController {
  @AuraEnabled(cacheable=true)
  public static ImageDTO getImage(Id recordId) {
    try {
      
      Bread__c bread = [SELECT Name, External_Id__c FROM Bread__c WHERE Id = :recordId LIMIT 1];

      if (String.isBlank(bread.External_Id__c)) {
        return null;
      }

      List<ContentVersion> recordImages = FileService.getFilesForRecord(recordId, bread.External_Id__c);
      return recordImages.isEmpty() ? null : new ImageDTO(recordImages[0], bread.Name);
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  public class ImageDTO {
    @AuraEnabled public String breadName;
    @AuraEnabled public String fileType;
    @AuraEnabled public String downloadUrl;

    public ImageDTO(ContentVersion cv, String breadName) {
      this.breadName = breadName;
      this.fileType = cv.FileType;
      this.downloadUrl = '/sfc/servlet.shepherd/version/renditionDownload' +
                         '?rendition=THUMB720BY480' +
                         '&versionId=' + cv.Id;
    }
  }
}
