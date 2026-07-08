public with sharing class BreadController {
  private static final String NAMED_CRED = 'callout:OpenRouteService';

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

  @AuraEnabled
  public static String optimiseRoute(String coordinatesJson) {
    try {
      List<Object> coords = (List<Object>) JSON.deserializeUntyped(coordinatesJson);

      List<Map<String, Object>> jobs = new List<Map<String, Object>>();
      for (Integer i = 1; i < coords.size(); i++) {
        Map<String, Object> job = new Map<String, Object>{
          'id'       => i,
          'location' => coords[i]
        };
        jobs.add(job);
      }

      Map<String, Object> vehicle = new Map<String, Object>{
        'id'      => 1,
        'profile' => 'driving-car',
        'start'   => coords[0],
        'end'     => coords[0]
      };

      Map<String, Object> body = new Map<String, Object>{
        'jobs'     => jobs,
        'vehicles' => new List<Object>{ vehicle }
      };

      HttpResponse res = HttpResponseService.makeCallout(
        NAMED_CRED,
        '/v2/optimization',
        JSON.serialize(body)
      );

      if (res.getStatusCode() != 200) {
        HttpResponseService.throwApiError(NAMED_CRED + ' Optimisation', res);
      }

      // Parse response and extract ordered job IDs
      Map<String, Object> data   = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
      List<Object>        routes = (List<Object>) data.get('routes');
      Map<String, Object> route  = (Map<String, Object>) routes[0];
      List<Object>        steps  = (List<Object>) route.get('steps');

      List<Integer> orderedJobIds = new List<Integer>();
      for (Object stepObj : steps) {
        Map<String, Object> step = (Map<String, Object>) stepObj;
        if (step.get('type') == 'job') {
          orderedJobIds.add(Integer.valueOf(step.get('job')));
        }
      }

      // Build the ordered coord list: start → optimised stops → start
      List<Object> orderedCoords = new List<Object>{ coords[0] };
      for (Integer jobId : orderedJobIds) {
        orderedCoords.add(coords[jobId]);
      }
      orderedCoords.add(coords[0]);

      Map<String, Object> result = new Map<String, Object>{
        'orderedJobIds' => orderedJobIds,
        'orderedCoords' => orderedCoords
      };

      return JSON.serialize(result);

    } catch (AuraHandledException e) {
      throw e;
    } catch (Exception e) {
      throw new AuraHandledException('optimiseRoute error: ' + e.getMessage());
    }
  }

  @AuraEnabled
  public static String getDirections(String orderedCoordsJson) {
    try {
      List<Object> coords = (List<Object>) JSON.deserializeUntyped(orderedCoordsJson);

      Map<String, Object> body = new Map<String, Object>{
        'coordinates' => coords
      };

      HttpResponse res = HttpResponseService.makeCallout(
        NAMED_CRED,
        '/v2/directions/driving-car/geojson',
        JSON.serialize(body)
      );

      if (res.getStatusCode() != 200) {
        HttpResponseService.throwApiError(NAMED_CRED + ' Directions', res);
      }

      // Return the raw GeoJSON — Leaflet will parse it in the browser
      return res.getBody();

    } catch (AuraHandledException e) {
      throw e;
    } catch (Exception e) {
      throw new AuraHandledException('getDirections error: ' + e.getMessage());
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
