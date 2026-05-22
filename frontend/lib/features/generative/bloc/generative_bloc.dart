import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';

import '../repository/generative_repository.dart';
import '../../quiz/models/quiz_models.dart';
import '../../quiz/repository/quiz_repository.dart';

part 'generative_event.dart';
part 'generative_state.dart';

class GenerativeBloc extends Bloc<GenerativeEvent, GenerativeState> {
  final GenerativeRepository _repository;
  final QuizRepository _quizRepository;

  GenerativeBloc(this._repository, this._quizRepository)
      : super(const GenerativeState()) {
    on<LoadConversations>(_onLoadConversations);
    on<CreateConversation>(_onCreateConversation);
    on<SelectConversation>(_onSelectConversation);
    on<DeleteConversation>(_onDeleteConversation);
    on<SendMessage>(_onSendMessage);
    on<GenerateText>(_onGenerateText);
    on<GenerateCode>(_onGenerateCode);
    on<ClearGenerativeResult>(_onClearResult);
    on<StartQuizSession>(_onStartQuizSession);
    on<AnswerQuizQuestion>(_onAnswerQuizQuestion);
    on<CancelQuizSession>(_onCancelQuizSession);
  }

  Future<void> _onStartQuizSession(
    StartQuizSession event,
    Emitter<GenerativeState> emit,
  ) async {
    emit(
      state.copyWith(
        status: GenerativeStatus.loading,
        quizStatus: QuizFlowStatus.loading,
        quizError: null,
      ),
    );

    try {
      final quiz = await _quizRepository.generateQuiz(
        topic: event.topic,
        questionCount: event.questionCount,
        difficulty: event.difficulty,
        formats: event.formats,
        language: event.language,
        model: event.model,
      );

      final introMessage = {
        'role': 'assistant',
        'content': _buildQuizIntroMessage(quiz),
        'timestamp': DateTime.now().toIso8601String(),
      };
      final firstQuestion = quiz.questions.isNotEmpty
          ? _buildQuizQuestionMessage(quiz.questions.first)
          : {
              'role': 'assistant',
              'content': 'Aucune question disponible pour ce quiz.',
              'timestamp': DateTime.now().toIso8601String(),
            };

      emit(
        state.copyWith(
          status: GenerativeStatus.success,
          quizStatus: QuizFlowStatus.active,
          activeQuiz: quiz,
          quizAnswers: const {},
          quizQuestionIndex: 0,
          messages: [...state.messages, introMessage, firstQuestion],
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: GenerativeStatus.failure,
          quizStatus: QuizFlowStatus.failure,
          quizError: e.toString(),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: GenerativeStatus.failure,
          quizStatus: QuizFlowStatus.failure,
          quizError: e.toString(),
        ),
      );
    }
  }

  Future<void> _onAnswerQuizQuestion(
    AnswerQuizQuestion event,
    Emitter<GenerativeState> emit,
  ) async {
    final quiz = state.activeQuiz;
    if (quiz == null || quiz.questions.isEmpty) {
      return;
    }

    final currentIndex = state.quizQuestionIndex;
    if (currentIndex < 0 || currentIndex >= quiz.questions.length) {
      return;
    }

    final question = quiz.questions[currentIndex];
    final userMessage = {
      'role': 'user',
      'content': event.answer,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final updatedAnswers = Map<int, String>.from(state.quizAnswers)
      ..[question.id] = event.answer;

    final updatedMessages = [...state.messages, userMessage];
    emit(
      state.copyWith(
        status: GenerativeStatus.sending,
        quizStatus: QuizFlowStatus.active,
        messages: updatedMessages,
        quizAnswers: updatedAnswers,
      ),
    );

    final nextIndex = currentIndex + 1;
    if (nextIndex < quiz.questions.length) {
      final nextQuestionMessage = _buildQuizQuestionMessage(
        quiz.questions[nextIndex],
      );
      emit(
        state.copyWith(
          status: GenerativeStatus.success,
          quizStatus: QuizFlowStatus.active,
          quizQuestionIndex: nextIndex,
          messages: [...updatedMessages, nextQuestionMessage],
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: GenerativeStatus.generating,
        quizStatus: QuizFlowStatus.grading,
      ),
    );

    try {
      final result = await _quizRepository.gradeQuiz(
        quizId: quiz.id,
        answers: updatedAnswers,
      );

      final summaryMessage = {
        'role': 'assistant',
        'content': _buildQuizScoreMessage(result),
        'timestamp': DateTime.now().toIso8601String(),
      };
      final detailMessage = {
        'role': 'assistant',
        'content': _buildQuizDetailMessage(result),
        'timestamp': DateTime.now().toIso8601String(),
      };
      final answerKeyMessage = {
        'role': 'assistant',
        'content': _buildQuizAnswerKeyMessage(quiz),
        'timestamp': DateTime.now().toIso8601String(),
      };

      emit(
        state.copyWith(
          status: GenerativeStatus.success,
          quizStatus: QuizFlowStatus.completed,
          quizResult: result,
          messages: [
            ...updatedMessages,
            summaryMessage,
            detailMessage,
            answerKeyMessage,
          ],
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: GenerativeStatus.failure,
          quizStatus: QuizFlowStatus.failure,
          quizError: e.toString(),
        ),
      );
    }
  }

  void _onCancelQuizSession(
    CancelQuizSession event,
    Emitter<GenerativeState> emit,
  ) {
    final message = {
      'role': 'assistant',
      'content':
          'Quiz annule. Vous pouvez relancer un autre quiz a tout moment.',
      'timestamp': DateTime.now().toIso8601String(),
    };
    emit(
      state.copyWith(
        quizStatus: QuizFlowStatus.initial,
        activeQuiz: null,
        quizAnswers: const {},
        quizQuestionIndex: 0,
        quizResult: null,
        quizError: null,
        messages: [...state.messages, message],
      ),
    );
  }

  String _buildQuizIntroMessage(Quiz quiz) {
    return ('Quiz interactif: ${quiz.title}\n'
        'Sujet: ${quiz.topic}\n'
        'Questions: ${quiz.questionCount} | Niveau: ${quiz.difficulty.toUpperCase()}\n'
        'Repondez a chaque question pour continuer.');
  }

  Map<String, dynamic> _buildQuizQuestionMessage(QuizQuestion question) {
    final buffer = StringBuffer();
    buffer.writeln('Question ${question.order}: ${question.prompt}');
    if (question.options.isNotEmpty) {
      for (final option in question.options) {
        buffer.writeln('- $option');
      }
    }
    if (question.type == 'open') {
      buffer.writeln('Reponse libre attendue.');
    }
    return {
      'role': 'assistant',
      'content': buffer.toString().trim(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  String _buildQuizScoreMessage(QuizResult result) {
    final maxScore = result.maxScore == 0 ? 1 : result.maxScore;
    final percent = ((result.score / maxScore) * 100).round();
    return 'Note: ${result.score.toStringAsFixed(1)} / ${result.maxScore} (${percent}%).';
  }

  String _buildQuizDetailMessage(QuizResult result) {
    final buffer = StringBuffer();
    buffer.writeln('Recapitulatif des reponses:');
    for (final item in result.results) {
      final status = item.isCorrect ? 'Bonne' : 'Mauvaise';
      buffer.writeln(
        '- Q${item.questionId}: $status. Reponse correcte: ${item.correctAnswer}',
      );
    }
    return buffer.toString().trim();
  }

  String _buildQuizAnswerKeyMessage(Quiz quiz) {
    final buffer = StringBuffer();
    buffer.writeln('Toutes les bonnes reponses:');
    for (final question in quiz.questions) {
      buffer.writeln('- Q${question.order}: ${question.correctAnswer}');
    }
    return buffer.toString().trim();
  }

  Future<Map<String, dynamic>> _buildImmediateFeedbackMessage({
    required int quizId,
    required QuizQuestion question,
    required Map<int, String> answers,
    required String model,
  }) async {
    try {
      final result = await _quizRepository.gradeQuiz(
        quizId: quizId,
        answers: {question.id: answers[question.id] ?? ''},
        model: model,
        partial: true,
        questionId: question.id,
      );

      final item = result.results.isNotEmpty ? result.results.first : null;
      if (item == null) {
        return {
          'role': 'assistant',
          'content': 'Feedback indisponible pour cette question.',
          'timestamp': DateTime.now().toIso8601String(),
        };
      }

      final status = item.isCorrect ? 'Bonne reponse' : 'Mauvaise reponse';
      final explanation = item.feedback.isNotEmpty
          ? item.feedback
          : (item.isCorrect
              ? 'Bonne reponse.'
              : 'La bonne reponse est: ${item.correctAnswer}');

      return {
        'role': 'assistant',
        'content': 'Feedback: $status\n$explanation',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (_) {
      return {
        'role': 'assistant',
        'content': 'Feedback indisponible pour cette question.',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  Future<void> _onLoadConversations(
    LoadConversations event,
    Emitter<GenerativeState> emit,
  ) async {
    emit(state.copyWith(status: GenerativeStatus.loading));

    try {
      final conversations = await _repository.getConversations();
      emit(
        state.copyWith(
          status: GenerativeStatus.success,
          conversations: conversations,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: GenerativeStatus.failure, error: e.toString()),
      );
    }
  }

  Future<void> _onCreateConversation(
    CreateConversation event,
    Emitter<GenerativeState> emit,
  ) async {
    try {
      final conversation = await _repository.createConversation(
        title: event.title,
      );
      emit(state.copyWith(currentConversation: conversation, messages: []));
    } catch (e) {
      emit(
        state.copyWith(status: GenerativeStatus.failure, error: e.toString()),
      );
    }
  }

  Future<void> _onSelectConversation(
    SelectConversation event,
    Emitter<GenerativeState> emit,
  ) async {
    emit(state.copyWith(status: GenerativeStatus.loading));

    try {
      final conversation = await _repository.getConversation(
        event.conversationId,
      );
      final messages = conversation['messages'] as List<dynamic>? ?? [];

      emit(
        state.copyWith(
          status: GenerativeStatus.success,
          currentConversation: conversation,
          messages: messages,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: GenerativeStatus.failure, error: e.toString()),
      );
    }
  }

  Future<void> _onDeleteConversation(
    DeleteConversation event,
    Emitter<GenerativeState> emit,
  ) async {
    try {
      await _repository.deleteConversation(event.conversationId);
      add(LoadConversations());
    } catch (e) {
      emit(
        state.copyWith(status: GenerativeStatus.failure, error: e.toString()),
      );
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<GenerativeState> emit,
  ) async {
    // Add user message to local state
    final userMessage = {
      'role': 'user',
      'content': event.message,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final updatedMessages = [...state.messages, userMessage];
    emit(
      state.copyWith(
        status: GenerativeStatus.sending,
        messages: updatedMessages,
      ),
    );

    try {
      final response = await _repository.sendMessage(
        conversationId: event.conversationId,
        message: event.message,
        model: event.model,
        latitude: event.latitude,
        longitude: event.longitude,
        radiusMeters: event.radiusMeters,
      );

      final apiSuccess = response['success'] != false;
      final responseText = (response['response'] ?? '').toString().trim();
      final apiError = (response['error'] ?? '').toString().trim();

      if (!apiSuccess || responseText.isEmpty) {
        final readableError = apiError.isNotEmpty
            ? apiError
            : 'Le modele n\'a renvoye aucune reponse.';

        final assistantMessage = {
          'role': 'assistant',
          'content': 'Erreur assistant: $readableError',
          'timestamp': DateTime.now().toIso8601String(),
        };

        emit(
          state.copyWith(
            status: GenerativeStatus.failure,
            messages: [...updatedMessages, assistantMessage],
            error: readableError,
          ),
        );
        return;
      }

      // Add assistant response
      final assistantMessage = {
        'role': 'assistant',
        'content': responseText,
        'timestamp': DateTime.now().toIso8601String(),
        if (response['places'] is List) 'places': response['places'],
        if (response['map_center'] is Map) 'map_center': response['map_center'],
      };

      emit(
        state.copyWith(
          status: GenerativeStatus.success,
          messages: [...updatedMessages, assistantMessage],
        ),
      );
    } on DioException catch (e) {
      final isTimeout = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout;

      if (isTimeout && event.model != 'ollama:llama3.2:1b') {
        try {
          final fallbackResponse = await _repository.sendMessage(
            conversationId: event.conversationId,
            message: event.message,
            model: 'ollama:llama3.2:1b',
            maxTokens: 192,
            latitude: event.latitude,
            longitude: event.longitude,
            radiusMeters: event.radiusMeters,
          );

          final assistantMessage = {
            'role': 'assistant',
            'content': fallbackResponse['response'] ?? '',
            'timestamp': DateTime.now().toIso8601String(),
            if (fallbackResponse['places'] is List)
              'places': fallbackResponse['places'],
            if (fallbackResponse['map_center'] is Map)
              'map_center': fallbackResponse['map_center'],
          };

          emit(
            state.copyWith(
              status: GenerativeStatus.success,
              messages: [...updatedMessages, assistantMessage],
              error:
                  'Mistral etait trop lent, reponse generee via Llama 3.2 1B.',
            ),
          );
          return;
        } catch (_) {
          // Ignore and fall through to normal timeout error.
        }
      }

      emit(
        state.copyWith(
          status: GenerativeStatus.failure,
          error: isTimeout
              ? 'Le modele local met trop de temps a repondre (timeout). '
                  'Reessayez ou utilisez un modele plus leger.'
              : e.toString(),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: GenerativeStatus.failure, error: e.toString()),
      );
    }
  }

  Future<void> _onGenerateText(
    GenerateText event,
    Emitter<GenerativeState> emit,
  ) async {
    emit(
      state.copyWith(
        status: GenerativeStatus.generating,
        currentOperation: 'Generating text...',
      ),
    );

    try {
      final result = await _repository.generateText(
        prompt: event.prompt,
        model: event.model,
        temperature: event.temperature,
      );

      emit(
        state.copyWith(
          status: GenerativeStatus.success,
          generatedContent:
              result['generated_text'] ?? result['response'] ?? '',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: GenerativeStatus.failure, error: e.toString()),
      );
    }
  }

  Future<void> _onGenerateCode(
    GenerateCode event,
    Emitter<GenerativeState> emit,
  ) async {
    emit(
      state.copyWith(
        status: GenerativeStatus.generating,
        currentOperation: 'Generating code...',
      ),
    );

    try {
      final result = await _repository.generateCode(
        prompt: event.prompt,
        language: event.language,
      );

      emit(
        state.copyWith(
          status: GenerativeStatus.success,
          generatedContent: result['code'] ??
              result['generated_code'] ??
              result['response'] ??
              '',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: GenerativeStatus.failure, error: e.toString()),
      );
    }
  }

  void _onClearResult(
    ClearGenerativeResult event,
    Emitter<GenerativeState> emit,
  ) {
    emit(state.copyWith(generatedContent: null, error: null));
  }
}
