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
      Integer n = coords.size();

      // ── Step 1: fetch duration matrix ────────────────────────────────
      // ORS matrix returns durations[i][j] = seconds from location i to j
      Map<String, Object> matrixBody = new Map<String, Object>{
        'locations' => coords,
        'metrics'   => new List<String>{ 'duration' },
        'sources'   => buildIndexList(n),
        'destinations' => buildIndexList(n)
      };

      HttpResponse matrixRes = HttpResponseService.makeCallout(
        NAMED_CRED,
        '/v2/matrix/driving-car',
        JSON.serialize(matrixBody),
        'application/json'
      );

      if (matrixRes.getStatusCode() != 200) {
        HttpResponseService.throwApiError(NAMED_CRED + ' Matrix', matrixRes);
      }

      Map<String, Object> matrixData = (Map<String, Object>) JSON.deserializeUntyped(matrixRes.getBody());
      List<Object> durationsRaw = (List<Object>) matrixData.get('durations');

      // Parse into a 2D Decimal array
      List<List<Decimal>> dist = new List<List<Decimal>>();
      for (Object row : durationsRaw) {
        List<Object>  rowList = (List<Object>) row;
        List<Decimal> rowDec  = new List<Decimal>();
        for (Object cell : rowList) {
          rowDec.add(cell == null ? 999999999 : Decimal.valueOf(String.valueOf(cell)));
        }
        dist.add(rowDec);
      }

      // ── Step 2: nearest-neighbour TSP from node 0 ───────────────────
      // Visits every stop (indices 1..n-1) exactly once, returns to 0.
      List<Boolean> visited   = new List<Boolean>();
      for (Integer i = 0; i < n; i++) { visited.add(false); }
      visited[0] = true;

      List<Integer> tour    = new List<Integer>{ 0 };
      Integer       current = 0;

      for (Integer step = 0; step < n - 1; step++) {
        Integer nearest  = -1;
        Decimal bestDist = 999999999;

        for (Integer j = 1; j < n; j++) {         // skip 0 (home)
          if (!visited[j] && dist[current][j] < bestDist) {
            bestDist = dist[current][j];
            nearest  = j;
          }
        }
        if (nearest == -1) break;                  // safety
        visited[nearest] = true;
        tour.add(nearest);
        current = nearest;
      }
      // tour is now [0, stopA, stopB, ...] — the home-return is implied

      // ── Step 3: build return values ──────────────────────────────────
      // orderedJobIds: the stop indices in visit order (excludes 0/home)
      List<Integer> orderedJobIds = new List<Integer>();
      for (Integer i = 1; i < tour.size(); i++) {
        orderedJobIds.add(tour[i]);
      }

      // orderedCoords: home → stops in order → home (for directions call)
      List<Object> orderedCoords = new List<Object>{ coords[0] };
      for (Integer idx : orderedJobIds) {
        orderedCoords.add(coords[idx]);
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
        JSON.serialize(body),
        'application/geo+json, application/json'
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

  private static List<Integer> buildIndexList(Integer n) {
    List<Integer> idx = new List<Integer>();
    for (Integer i = 0; i < n; i++) { idx.add(i); }
    return idx;
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
