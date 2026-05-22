part of 'quiz_bloc.dart';

enum QuizStatus { initial, loading, ready, submitting, submitted, failure }

class QuizState extends Equatable {
  final QuizStatus status;
  final Quiz? quiz;
  final QuizResult? result;
  final String? error;

  const QuizState({
    this.status = QuizStatus.initial,
    this.quiz,
    this.result,
    this.error,
  });

  QuizState copyWith({
    QuizStatus? status,
    Quiz? quiz,
    QuizResult? result,
    String? error,
  }) {
    return QuizState(
      status: status ?? this.status,
      quiz: quiz ?? this.quiz,
      result: result ?? this.result,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, quiz, result, error];
}
