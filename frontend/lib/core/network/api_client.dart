import 'package:dio/dio.dart';

class ApiClient {
  final Dio _dio;
  final Options _nlpOptions = Options(
    sendTimeout: const Duration(seconds: 45),
    receiveTimeout: const Duration(minutes: 4),
  );
  final Options _generativeOptions = Options(
    sendTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 3),
  );
  final Options _ecoOptions = Options(
    sendTimeout: const Duration(seconds: 45),
    receiveTimeout: const Duration(minutes: 2),
  );

  ApiClient(this._dio);

  // Auth
  Future<Response> register(Map<String, dynamic> data) =>
      _dio.post('/auth/register/', data: data);

  Future<Response> login(Map<String, dynamic> data) =>
      _dio.post('/auth/login/', data: data);

  Future<Response> logout(String refreshToken) =>
      _dio.post('/auth/logout/', data: {'refresh': refreshToken});

  Future<Response> getProfile() => _dio.get('/auth/profile/');

  Future<Response> updateProfile(Map<String, dynamic> data) =>
      _dio.patch('/auth/profile/', data: data);

    Future<Response> getUserStats() => _dio.get('/auth/stats/');

    Future<Response> createRecyclingEvents(List<Map<String, dynamic>> events) =>
            _dio.post('/auth/recycling-events/', data: {'events': events});

  // Vision
  Future<Response> performOCR(FormData data) =>
      _dio.post('/vision/ocr/', data: data);

  Future<Response> detectObjects(FormData data) =>
      _dio.post('/vision/detect-objects/', data: data);

  Future<Response> detectFaces(FormData data) =>
      _dio.post('/vision/detect-faces/', data: data);

  Future<Response> labelImage(FormData data) =>
      _dio.post('/vision/label-image/', data: data);

  Future<Response> getVisionHistory() => _dio.get('/vision/history/');

  // NLP
  Future<Response> analyzeSentiment(Map<String, dynamic> data) =>
      _dio.post('/nlp/sentiment/', data: data, options: _nlpOptions);

  Future<Response> extractEntities(Map<String, dynamic> data) =>
      _dio.post('/nlp/entities/', data: data, options: _nlpOptions);

  Future<Response> detectLanguage(Map<String, dynamic> data) =>
      _dio.post('/nlp/detect-language/', data: data, options: _nlpOptions);

  Future<Response> translate(Map<String, dynamic> data) =>
      _dio.post('/nlp/translate/', data: data, options: _nlpOptions);

  Future<Response> summarize(Map<String, dynamic> data) =>
      _dio.post('/nlp/summarize/', data: data, options: _nlpOptions);

  Future<Response> classify(Map<String, dynamic> data) =>
      _dio.post('/nlp/classify/', data: data, options: _nlpOptions);

  Future<Response> getNLPHistory() => _dio.get('/nlp/history/');

  // Generative
  Future<Response> chat(Map<String, dynamic> data) =>
      _dio.post('/generative/chat/', data: data, options: _generativeOptions);

  Future<Response> generateText(Map<String, dynamic> data) => _dio.post(
        '/generative/generate-text/',
        data: data,
        options: _generativeOptions,
      );

  Future<Response> generateCode(Map<String, dynamic> data) => _dio.post(
        '/generative/generate-code/',
        data: data,
        options: _generativeOptions,
      );

  Future<Response> getConversations() => _dio.get('/generative/conversations/');

  Future<Response> createConversation(Map<String, dynamic> data) =>
      _dio.post('/generative/conversations/', data: data);

  Future<Response> getConversation(int id) =>
      _dio.get('/generative/conversations/$id/');

  Future<Response> deleteConversation(int id) =>
      _dio.delete('/generative/conversations/$id/');

  Future<Response> generate(Map<String, dynamic> data) =>
      _dio.post('/generative/generate-text/', data: data);

  Future<Response> getGenerationHistory() => _dio.get('/generative/history/');

  // DataHub
  Future<Response> collectYouTube(Map<String, dynamic> data) =>
      _dio.post('/datahub/collect/youtube/', data: data);

  Future<Response> collectFacebook(Map<String, dynamic> data) =>
      _dio.post('/datahub/collect/facebook/', data: data);

  Future<Response> collectGoogleMaps(Map<String, dynamic> data) =>
      _dio.post('/datahub/collect/google-maps/', data: data);

  Future<Response> getDataHubRecords({String? source}) =>
      _dio.get('/datahub/records/', queryParameters: {
        if (source != null && source.isNotEmpty) 'source': source,
      });

  Future<Response> getDataHubJobs() => _dio.get('/datahub/jobs/');

  // Quiz
  Future<Response> generateQuiz(Map<String, dynamic> data) =>
      _dio.post('/quiz/generate/', data: data, options: _generativeOptions);

  Future<Response> getQuizHistory() => _dio.get('/quiz/history/');

  Future<Response> getQuiz(int id) => _dio.get('/quiz/$id/');

  Future<Response> gradeQuiz(Map<String, dynamic> data) =>
      _dio.post('/quiz/grade/', data: data, options: _generativeOptions);

  Future<Response> getQuizLatestAttempt(int quizId) =>
      _dio.get('/quiz/attempts/latest/', queryParameters: {
        'quiz_id': quizId,
      });

  // Eco-smart
  Future<Response> ecoClassify(Map<String, dynamic> data) =>
      _dio.post('/eco-smart/classify/', data: data, options: _ecoOptions);

  Future<Response> ecoEstimate(Map<String, dynamic> data) =>
      _dio.post('/eco-smart/estimate/', data: data, options: _ecoOptions);

  Future<Response> ecoCluster(Map<String, dynamic> data) =>
      _dio.post('/eco-smart/cluster/', data: data, options: _ecoOptions);

  Future<Response> ecoNlp(Map<String, dynamic> data) =>
      _dio.post('/eco-smart/nlp/', data: data, options: _ecoOptions);

  Future<Response> ecoMultimodal(Map<String, dynamic> data) =>
      _dio.post('/eco-smart/multimodal/', data: data, options: _ecoOptions);

    Future<Response> getEcoCenters() => _dio.get('/eco-smart/centers/');
}
