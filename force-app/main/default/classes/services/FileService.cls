public with sharing class FileService {

  public static List<ContentVersion> getFilesForRecord(Id recordId, String externalId) {
    Set<Id> docIds = ContentDocumentLinkSelector.getDocIdsByRecord(recordId);
    return ContentVersionSelector.getByDocumentIds(docIds, externalId);
  }
}
