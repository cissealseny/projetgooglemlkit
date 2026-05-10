import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';

import '../repository/generative_repository.dart';

part 'generative_event.dart';
part 'generative_state.dart';

class GenerativeBloc extends Bloc<GenerativeEvent, GenerativeState> {
  final GenerativeRepository _repository;

  GenerativeBloc(this._repository) : super(const GenerativeState()) {
    on<LoadConversations>(_onLoadConversations);
    on<CreateConversation>(_onCreateConversation);
    on<SelectConversation>(_onSelectConversation);
    on<DeleteConversation>(_onDeleteConversation);
    on<SendMessage>(_onSendMessage);
    on<GenerateText>(_onGenerateText);
    on<GenerateCode>(_onGenerateCode);
    on<ClearGenerativeResult>(_onClearResult);
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
