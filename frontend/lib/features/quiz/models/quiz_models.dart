class QuizQuestion {
  final int id;
  final int order;
  final String type;
  final String prompt;
  final List<String> options;
  final String correctAnswer;
  final String explanation;

  QuizQuestion({
    required this.id,
    required this.order,
    required this.type,
    required this.prompt,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: (json['id'] ?? 0) as int,
      order: (json['order'] ?? 0) as int,
      type: (json['question_type'] ?? json['type'] ?? 'mcq').toString(),
      prompt: (json['prompt'] ?? json['question'] ?? '').toString(),
      options: (json['options'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => e.toString())
          .toList(),
      correctAnswer:
          (json['correct_answer'] ?? json['answer'] ?? '').toString(),
      explanation: (json['explanation'] ?? '').toString(),
    );
  }
}

class Quiz {
  final int id;
  final String title;
  final String topic;
  final String language;
  final String difficulty;
  final int questionCount;
  final List<String> formats;
  final String model;
  final List<QuizQuestion> questions;

  Quiz({
    required this.id,
    required this.title,
    required this.topic,
    required this.language,
    required this.difficulty,
    required this.questionCount,
    required this.formats,
    required this.model,
    required this.questions,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: (json['id'] ?? 0) as int,
      title: (json['title'] ?? '').toString(),
      topic: (json['topic'] ?? '').toString(),
      language: (json['language'] ?? 'auto').toString(),
      difficulty: (json['difficulty'] ?? 'medium').toString(),
      questionCount: (json['question_count'] ?? 0) as int,
      formats: (json['formats'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => e.toString())
          .toList(),
      model: (json['model'] ?? '').toString(),
      questions: (json['questions'] as List<dynamic>? ?? const <dynamic>[])
          .map(
              (e) => QuizQuestion.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class QuizSummary {
  final int id;
  final String title;
  final String topic;
  final String difficulty;
  final int questionCount;
  final String createdAt;

  QuizSummary({
    required this.id,
    required this.title,
    required this.topic,
    required this.difficulty,
    required this.questionCount,
    required this.createdAt,
  });

  factory QuizSummary.fromJson(Map<String, dynamic> json) {
    return QuizSummary(
      id: (json['id'] ?? 0) as int,
      title: (json['title'] ?? '').toString(),
      topic: (json['topic'] ?? '').toString(),
      difficulty: (json['difficulty'] ?? '').toString(),
      questionCount: (json['question_count'] ?? 0) as int,
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}

class QuizAnswerResult {
  final int questionId;
  final String questionType;
  final bool isCorrect;
  final double score;
  final String correctAnswer;
  final String feedback;

  QuizAnswerResult({
    required this.questionId,
    required this.questionType,
    required this.isCorrect,
    required this.score,
    required this.correctAnswer,
    required this.feedback,
  });

  factory QuizAnswerResult.fromJson(Map<String, dynamic> json) {
    return QuizAnswerResult(
      questionId: (json['question_id'] ?? 0) as int,
      questionType: (json['question_type'] ?? '').toString(),
      isCorrect: (json['is_correct'] ?? false) as bool,
      score: (json['score'] ?? 0).toDouble(),
      correctAnswer: (json['correct_answer'] ?? '').toString(),
      feedback: (json['feedback'] ?? '').toString(),
    );
  }
}

class QuizResult {
  final double score;
  final int maxScore;
  final List<QuizAnswerResult> results;

  QuizResult({
    required this.score,
    required this.maxScore,
    required this.results,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      score: (json['score'] ?? 0).toDouble(),
      maxScore: (json['max_score'] ?? 0) as int,
      results: (json['results'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) =>
              QuizAnswerResult.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
