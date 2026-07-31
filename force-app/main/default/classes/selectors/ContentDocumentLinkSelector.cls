public with sharing class ContentDocumentLinkSelector {

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
