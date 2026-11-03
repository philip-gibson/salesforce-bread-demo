@RestResource(urlMapping='/openRouteServiceResource/*')
global with sharing class OpenRouteServiceResource {
  @HttpPost
  global static String optimiseRoute(String coordinatesJson) {
    // call OpenRouteService.optimiseRoute(coordinatesJson)
    // call getDirections(orderedCoordsJson) here and not as a second call
    return 'Success: ' + inputParam;
  }
}
