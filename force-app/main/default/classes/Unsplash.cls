public with sharing class Unsplash {
  private static final String ACCESS_KEY = '0JAr42IcJBA4UFNgISwbhWssLfJJeIHtPiflS6-Xwzg';

  public static String getImageUrl(String query) {
    if (String.isBlank(query)) {
      return null;
    }

    Http http = new Http();
    HttpRequest req = new HttpRequest();

    String endpoint =
      'https://api.unsplash.com/search/photos' +
      '?query=' +
      EncodingUtil.urlEncode(query, 'UTF-8') +
      '&per_page=1';

    req.setEndpoint(endpoint);
    req.setMethod('GET');
    req.setHeader('Authorization', 'Client-ID ' + ACCESS_KEY);

    HttpResponse res = http.send(req);

    if (res.getStatusCode() != 200) {
      throw new AuraHandledException('Unsplash API error');
    }

    Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(
      res.getBody()
    );

    List<Object> results = (List<Object>) payload.get('results');

    if (results.isEmpty()) {
      return null;
    }

    Map<String, Object> first = (Map<String, Object>) results[0];

    Map<String, Object> urls = (Map<String, Object>) first.get('urls');

    return (String) urls.get('small');
  }
}
