import '../../../core/network/api_client.dart';
import '../services/mlkit_nlp_service.dart';

class NLPRepository {
  final ApiClient _apiClient;
  final MLKitNLPService _mlkitService;

  NLPRepository(this._apiClient, this._mlkitService);

  // Language Detection
  Future<Map<String, dynamic>> detectLanguageLocal(String text) async {
    return await _mlkitService.identifyLanguage(text);
  }

  Future<Map<String, dynamic>> detectLanguageRemote(String text) async {
    final response = await _apiClient.detectLanguage({'text': text});
    return response.data;
  }

  // Translation
  Future<Map<String, dynamic>> translateLocal(
    String text, {
    String sourceLang = 'en',
    String targetLang = 'fr',
  }) async {
    return await _mlkitService.translateText(
      text,
      sourceLang: sourceLang,
      targetLang: targetLang,
    );
  }

  Future<Map<String, dynamic>> translateRemote(
    String text, {
    String sourceLang = 'auto',
    String targetLang = 'en',
    String provider = 'auto',
  }) async {
    final response = await _apiClient.translate({
      'text': text,
      'source_language': sourceLang,
      'target_language': targetLang,
      'provider': provider,
    });
    return response.data;
  }

  // Sentiment Analysis (remote only)
  Future<Map<String, dynamic>> analyzeSentiment(
    String text, {
    String provider = 'auto',
  }) async {
    final response = await _apiClient.analyzeSentiment({
      'text': text,
      'provider': provider,
    });
    return response.data;
  }

  // Entity Extraction
  Future<Map<String, dynamic>> extractEntitiesLocal(
    String text, {
    String language = 'en',
  }) async {
    return await _mlkitService.extractEntities(text, language: language);
  }

  Future<Map<String, dynamic>> extractEntitiesRemote(
    String text, {
    String provider = 'auto',
  }) async {
    final response = await _apiClient.extractEntities({
      'text': text,
      'provider': provider,
    });
    return response.data;
  }

  // Text Summarization (remote only)
  Future<Map<String, dynamic>> summarizeText(
    String text, {
    int maxLength = 150,
    int minLength = 50,
    String provider = 'auto',
  }) async {
    final response = await _apiClient.summarize({
      'text': text,
      'max_length': maxLength,
      'min_length': minLength,
      'provider': provider,
    });
    return response.data;
  }

  // Text Classification (remote only)
  Future<Map<String, dynamic>> classifyText(
    String text, {
    List<String>? categories,
    String provider = 'auto',
  }) async {
    final response = await _apiClient.classify({
      'text': text,
      if (categories != null) 'categories': categories,
      'provider': provider,
    });
    return response.data;
  }

  // Smart Reply (local only)
  Future<Map<String, dynamic>> generateSmartReplies(
    List<Map<String, dynamic>> conversation,
  ) async {
    return await _mlkitService.generateSmartReplies(conversation);
  }

  // History
  Future<List<dynamic>> getHistory() async {
    final response = await _apiClient.getNLPHistory();
    // Handle Django paginated response
    final data = response.data;
    if (data is List) return data;
    if (data is Map && data.containsKey('results')) {
      return data['results'] as List<dynamic>;
    }
    return [];
  }

  // Supported Languages
  List<String> getSupportedTranslationLanguages() {
    return _mlkitService.getSupportedTranslationLanguages();
  }
}
