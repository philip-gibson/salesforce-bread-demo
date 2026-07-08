public with sharing class HttpResponseService {
  public static HttpResponse makeCallout(String NAMED_CRED, String path, String jsonBody) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint(NAMED_CRED + path);
    req.setMethod('POST');
    req.setHeader('Content-Type', 'application/json');
    req.setHeader('Accept', 'application/json');
    req.setTimeout(30000);
    req.setBody(jsonBody);

    return new Http().send(req);
  }

  public static void throwApiError(String context, HttpResponse res) {
    String msg = context + ' API error (' + res.getStatusCode() + ')';
    try {
        Map<String, Object> err = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        Map<String, Object> errObj = (Map<String, Object>) err.get('error');
        if (errObj != null && errObj.get('message') != null) {
          msg += ': ' + (String) errObj.get('message');
        }
    } catch (Exception e) { /* ignore parse failures */ }
    throw new AuraHandledException(msg);
  }
}
