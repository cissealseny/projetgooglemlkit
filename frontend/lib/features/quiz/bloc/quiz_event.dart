part of 'quiz_bloc.dart';

abstract class QuizEvent extends Equatable {
  const QuizEvent();

  @override
  List<Object?> get props => [];
}

class GenerateQuiz extends QuizEvent {
  final String topic;
  final int questionCount;
  final String difficulty;
  final List<String> formats;
  final String language;
  final String model;

  const GenerateQuiz({
    required this.topic,
    required this.questionCount,
    required this.difficulty,
    required this.formats,
    required this.language,
    required this.model,
  });

  @override
  List<Object?> get props =>
      [topic, questionCount, difficulty, formats, language, model];
}

class LoadQuiz extends QuizEvent {
  final int quizId;

  const LoadQuiz({required this.quizId});

  @override
  List<Object?> get props => [quizId];
}

class SubmitQuiz extends QuizEvent {
  final int quizId;
  final Map<int, String> answers;
  final String? model;

  const SubmitQuiz({
    required this.quizId,
    required this.answers,
    this.model,
  });

  @override
  List<Object?> get props => [quizId, answers, model];
}

class ResetQuiz extends QuizEvent {}
