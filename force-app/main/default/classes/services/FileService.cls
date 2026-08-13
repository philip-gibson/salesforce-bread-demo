public with sharing class FileService {

  public static List<ContentVersion> getFilesForRecord(Id recordId, String externalId) {
    Set<Id> docIds = ContentDocumentLinksSelector.getDocIdsByRecord(recordId);
    return ContentVersionsSelector.getByDocumentIds(docIds, externalId);
  }
}
