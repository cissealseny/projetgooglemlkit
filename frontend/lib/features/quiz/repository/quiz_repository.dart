import '../../../core/network/api_client.dart';
import '../models/quiz_models.dart';

class QuizRepository {
  final ApiClient _apiClient;

  QuizRepository(this._apiClient);

  Map<String, dynamic> _asStringKeyedMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  List<dynamic> _asList(dynamic data) {
    if (data is List) return data;
    return const <dynamic>[];
  }

  Future<Quiz> generateQuiz({
    required String topic,
    required int questionCount,
    required String difficulty,
    required List<String> formats,
    required String language,
    required String model,
  }) async {
    final response = await _apiClient.generateQuiz({
      'topic': topic,
      'question_count': questionCount,
      'difficulty': difficulty,
      'formats': formats,
      'language': language,
      'model': model,
    });

    final data = _asStringKeyedMap(response.data);
    final quizData = data['quiz'] is Map ? data['quiz'] : data;
    return Quiz.fromJson(Map<String, dynamic>.from(quizData as Map));
  }

  Future<Quiz> getQuiz(int id) async {
    final response = await _apiClient.getQuiz(id);
    return Quiz.fromJson(_asStringKeyedMap(response.data));
  }

  Future<List<QuizSummary>> getHistory() async {
    final response = await _apiClient.getQuizHistory();
    final data = response.data;
    if (data is List) {
      return data
          .map((e) => QuizSummary.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    if (data is Map && data.containsKey('results')) {
      return _asList(data['results'])
          .map((e) => QuizSummary.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return const <QuizSummary>[];
  }

  Future<QuizResult> gradeQuiz({
    required int quizId,
    required Map<int, String> answers,
    String? model,
    bool partial = false,
    int? questionId,
  }) async {
    final payload = {
      'quiz_id': quizId,
      'answers': answers.entries
          .map((entry) => {
                'question_id': entry.key,
                'answer': entry.value,
              })
          .toList(),
      if (model != null && model.isNotEmpty) 'model': model,
      if (partial) 'partial': true,
      if (partial && questionId != null) 'question_id': questionId,
    };

    final response = await _apiClient.gradeQuiz(payload);
    return QuizResult.fromJson(_asStringKeyedMap(response.data));
  }

  Future<QuizResult> getLatestAttempt(int quizId) async {
    final response = await _apiClient.getQuizLatestAttempt(quizId);
    return QuizResult.fromJson(_asStringKeyedMap(response.data));
  }
}
