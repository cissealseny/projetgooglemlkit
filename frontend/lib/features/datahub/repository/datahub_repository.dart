import '../../../core/network/api_client.dart';

class DataHubRepository {
  final ApiClient _apiClient;

  DataHubRepository(this._apiClient);

  Map<String, dynamic> _asStringKeyedMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  List<dynamic> _asList(dynamic data) {
    if (data is List) return data;
    return const <dynamic>[];
  }

  Future<Map<String, dynamic>> collectYouTube({
    required String query,
    int maxResults = 20,
    String order = 'date',
  }) async {
    final response = await _apiClient.collectYouTube({
      'query': query,
      'max_results': maxResults,
      'order': order,
    });
    return _asStringKeyedMap(response.data);
  }

  Future<Map<String, dynamic>> collectFacebook({
    required String pageId,
    int limit = 25,
  }) async {
    final response = await _apiClient.collectFacebook({
      'page_id': pageId,
      'limit': limit,
    });
    return _asStringKeyedMap(response.data);
  }

  Future<Map<String, dynamic>> collectGoogleMaps({
    required String query,
    required double latitude,
    required double longitude,
    int radius = 2000,
    String placeType = 'restaurant',
    int maxResults = 5,
  }) async {
    final safeMaxResults = maxResults.clamp(1, 5).toInt();
    final response = await _apiClient.collectGoogleMaps({
      'query': query,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'place_type': placeType,
      'max_results': safeMaxResults,
    });
    return _asStringKeyedMap(response.data);
  }

  Future<List<dynamic>> getRecords({String? source}) async {
    final response = await _apiClient.getDataHubRecords(source: source);
    final data = response.data;
    if (data is List) return data;
    if (data is Map && data.containsKey('results')) {
      return _asList(data['results']);
    }
    return const <dynamic>[];
  }

  Future<List<dynamic>> getJobs() async {
    final response = await _apiClient.getDataHubJobs();
    final data = response.data;
    if (data is List) return data;
    if (data is Map && data.containsKey('results')) {
      return _asList(data['results']);
    }
    return const <dynamic>[];
  }
}
