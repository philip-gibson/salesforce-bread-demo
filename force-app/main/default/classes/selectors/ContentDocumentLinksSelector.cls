public with sharing class ContentDocumentLinksSelector {

  public static Set<Id> getDocIdsByRecord(Id recordId) {
    Set<Id> docIds = new Set<Id>();

    for (ContentDocumentLink link : [
      SELECT ContentDocumentId 
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :recordId
    ]) {
      docIds.add(link.ContentDocumentId);
    }

    return docIds;
  }
}
