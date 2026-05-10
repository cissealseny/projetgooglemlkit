import '../../../core/network/api_client.dart';

class GenerativeRepository {
  final ApiClient _apiClient;

  GenerativeRepository(this._apiClient);

  Map<String, dynamic> _asStringKeyedMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  List<dynamic> _asList(dynamic data) {
    if (data is List) return data;
    return const <dynamic>[];
  }

  // Conversations
  Future<List<dynamic>> getConversations() async {
    final response = await _apiClient.getConversations();
    // Handle Django paginated response
    final data = response.data;
    if (data is List) return data;
    if (data is Map && data.containsKey('results')) {
      return _asList(data['results']);
    }
    return const <dynamic>[];
  }

  Future<Map<String, dynamic>> createConversation({String? title}) async {
    final response = await _apiClient.createConversation({
      if (title != null) 'title': title,
    });
    return _asStringKeyedMap(response.data);
  }

  Future<Map<String, dynamic>> getConversation(int id) async {
    final response = await _apiClient.getConversation(id);
    return _asStringKeyedMap(response.data);
  }

  Future<void> deleteConversation(int id) async {
    await _apiClient.deleteConversation(id);
  }

  // Chat Messages
  Future<Map<String, dynamic>> sendMessage({
    required int conversationId,
    required String message,
    String model = 'ollama:mistral:7b',
    int maxTokens = 256,
    double? latitude,
    double? longitude,
    int? radiusMeters,
  }) async {
    final response = await _apiClient.chat({
      'conversation_id': conversationId,
      'message': message,
      'model': model,
      'max_tokens': maxTokens,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (radiusMeters != null) 'radius_meters': radiusMeters,
    });
    return _asStringKeyedMap(response.data);
  }

  // Generation
  Future<Map<String, dynamic>> generateText({
    required String prompt,
    String model = 'ollama:mistral:7b',
    int maxTokens = 1024,
    double temperature = 0.7,
  }) async {
    final response = await _apiClient.generateText({
      'prompt': prompt,
      'model': model,
      'max_tokens': maxTokens,
      'temperature': temperature,
    });
    return _asStringKeyedMap(response.data);
  }

  // Code Generation
  Future<Map<String, dynamic>> generateCode({
    required String prompt,
    String language = 'python',
  }) async {
    final response = await _apiClient.generateCode({
      'prompt': prompt,
      'language': language,
    });
    return _asStringKeyedMap(response.data);
  }
}
