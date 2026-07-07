public with sharing class ContentVersionSelector {

  public static List<ContentVersion> getByDocumentIds(Set<Id> docIds, String externalId) {
    String query = 'SELECT FileType ' +
                   'FROM ContentVersion ' +
                   'WHERE ContentDocumentId IN :docIds ' +
                   'AND IsLatest = true';

    if (String.isNotBlank(externalId)) {
      query += ' AND Title = :externalId';
    }

    query += ' WITH USER_MODE';

    return Database.query(query);
  }
}
