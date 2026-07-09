public with sharing class HttpResponseService {
  public static HttpResponse makeCallout(String NAMED_CRED, String path, String jsonBody, String acceptHeader) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint(NAMED_CRED + path);
    req.setMethod('POST');
    req.setHeader('Content-Type', 'application/json');
    req.setHeader('Accept', acceptHeader);
    // req.setHeader('Authorization', 'Bearer {!$Credential.ORS_Api_Key.Authorization}'); // why does this work?
    req.setTimeout(30000);
    req.setBody(jsonBody);

    return new Http().send(req);
  }

  public static void throwApiError(String context, HttpResponse res) {
    String msg = context + ' API error (' + res.getStatusCode() + ')';
    try {
      Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
      Object errObj = body.get('error');
      if (errObj instanceof String) {
        msg += ': ' + (String) errObj;
      } else if (errObj instanceof Map<String, Object>) {
        Map<String, Object> errMap = (Map<String, Object>) errObj;
        if (errMap.get('message') != null) {
          msg += ': ' + (String) errMap.get('message');
        }
      }
    } catch (Exception e) { /* ignore parse failures */ }
    throw new AuraHandledException(msg);
  }
}
