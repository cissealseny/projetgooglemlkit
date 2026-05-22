import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';

import '../repository/quiz_repository.dart';
import '../models/quiz_models.dart';

part 'quiz_event.dart';
part 'quiz_state.dart';

class QuizBloc extends Bloc<QuizEvent, QuizState> {
  final QuizRepository _repository;

  QuizBloc(this._repository) : super(const QuizState()) {
    on<GenerateQuiz>(_onGenerateQuiz);
    on<LoadQuiz>(_onLoadQuiz);
    on<SubmitQuiz>(_onSubmitQuiz);
    on<ResetQuiz>(_onResetQuiz);
  }

  Future<void> _onGenerateQuiz(
    GenerateQuiz event,
    Emitter<QuizState> emit,
  ) async {
    emit(state.copyWith(status: QuizStatus.loading));

    try {
      final quiz = await _repository.generateQuiz(
        topic: event.topic,
        questionCount: event.questionCount,
        difficulty: event.difficulty,
        formats: event.formats,
        language: event.language,
        model: event.model,
      );
      emit(state.copyWith(status: QuizStatus.ready, quiz: quiz));
    } on DioException catch (e) {
      emit(state.copyWith(status: QuizStatus.failure, error: e.toString()));
    } catch (e) {
      emit(state.copyWith(status: QuizStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onLoadQuiz(
    LoadQuiz event,
    Emitter<QuizState> emit,
  ) async {
    emit(state.copyWith(status: QuizStatus.loading));

    try {
      final quiz = await _repository.getQuiz(event.quizId);
      emit(state.copyWith(status: QuizStatus.ready, quiz: quiz));
    } on DioException catch (e) {
      emit(state.copyWith(status: QuizStatus.failure, error: e.toString()));
    } catch (e) {
      emit(state.copyWith(status: QuizStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onSubmitQuiz(
    SubmitQuiz event,
    Emitter<QuizState> emit,
  ) async {
    emit(state.copyWith(status: QuizStatus.submitting));

    try {
      final result = await _repository.gradeQuiz(
        quizId: event.quizId,
        answers: event.answers,
        model: event.model,
      );
      emit(state.copyWith(status: QuizStatus.submitted, result: result));
    } on DioException catch (e) {
      emit(state.copyWith(status: QuizStatus.failure, error: e.toString()));
    } catch (e) {
      emit(state.copyWith(status: QuizStatus.failure, error: e.toString()));
    }
  }

  void _onResetQuiz(
    ResetQuiz event,
    Emitter<QuizState> emit,
  ) {
    emit(const QuizState());
  }
}
