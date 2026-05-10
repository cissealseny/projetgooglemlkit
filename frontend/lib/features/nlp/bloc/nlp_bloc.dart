import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';

import '../repository/nlp_repository.dart';

part 'nlp_event.dart';
part 'nlp_state.dart';

class NLPBloc extends Bloc<NLPEvent, NLPState> {
  final NLPRepository _repository;
  static const String _authErrorMessage =
      'Session expiree ou non connecte. Reconnectez-vous puis reessayez.';

  NLPBloc(this._repository) : super(const NLPState()) {
    on<AnalyzeSentiment>(_onAnalyzeSentiment);
    on<DetectLanguage>(_onDetectLanguage);
    on<TranslateText>(_onTranslateText);
    on<ExtractEntities>(_onExtractEntities);
    on<SummarizeText>(_onSummarizeText);
    on<ClassifyText>(_onClassifyText);
    on<GenerateSmartReplies>(_onGenerateSmartReplies);
    on<ClearNLPResult>(_onClearResult);
  }

  Future<void> _onAnalyzeSentiment(
    AnalyzeSentiment event,
    Emitter<NLPState> emit,
  ) async {
    emit(
      state.copyWith(
        status: NLPStatus.loading,
        currentOperation: 'Sentiment Analysis',
      ),
    );

    try {
      final result = await _repository.analyzeSentiment(
        event.text,
        provider: event.provider,
      );

      if (result['success'] == true) {
        emit(state.copyWith(status: NLPStatus.success, result: result));
      } else {
        emit(
          state.copyWith(
            status: NLPStatus.failure,
            error: result['error'] ?? 'Sentiment analysis failed',
          ),
        );
      }
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: NLPStatus.failure,
          error: _mapDioError(e),
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: NLPStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onDetectLanguage(
    DetectLanguage event,
    Emitter<NLPState> emit,
  ) async {
    emit(
      state.copyWith(
        status: NLPStatus.loading,
        currentOperation: 'Language Detection',
      ),
    );

    try {
      final result = event.useLocal
          ? await _repository.detectLanguageLocal(event.text)
          : await _repository.detectLanguageRemote(event.text);

      if (result['success'] == true) {
        emit(state.copyWith(status: NLPStatus.success, result: result));
      } else {
        emit(
          state.copyWith(
            status: NLPStatus.failure,
            error: result['error'] ?? 'Language detection failed',
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(status: NLPStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onTranslateText(
    TranslateText event,
    Emitter<NLPState> emit,
  ) async {
    emit(
      state.copyWith(
        status: NLPStatus.loading,
        currentOperation: 'Translation',
      ),
    );

    try {
      Map<String, dynamic> result;

      if (event.useLocal) {
        result = await _repository.translateLocal(
          event.text,
          sourceLang: event.sourceLang,
          targetLang: event.targetLang,
        );
      } else {
        try {
          result = await _repository.translateRemote(
            event.text,
            sourceLang: event.sourceLang,
            targetLang: event.targetLang,
            provider: event.provider,
          );
        } on DioException catch (e) {
          // If backend translation is unavailable, fall back to on-device ML Kit.
          final isNetworkIssue = e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.unknown;

          if (!isNetworkIssue) rethrow;

          result = await _repository.translateLocal(
            event.text,
            sourceLang: event.sourceLang,
            targetLang: event.targetLang,
          );

          if (result['success'] == true) {
            result['warning'] =
                'Serveur indisponible, traduction locale ML Kit utilisee.';
            result['fallbackToLocal'] = true;
          }
        }
      }

      if (result['success'] == true) {
        emit(state.copyWith(status: NLPStatus.success, result: result));
      } else {
        emit(
          state.copyWith(
            status: NLPStatus.failure,
            error: result['error'] ??
                'Traduction impossible. Reessayez ou activez le mode local.',
          ),
        );
      }
    } on DioException catch (e) {
      final isUnauthorized = e.response?.statusCode == 401;
      emit(
        state.copyWith(
          status: NLPStatus.failure,
          error: isUnauthorized
              ? _authErrorMessage
              : 'Echec de traduction: ${e.toString()}\n'
                  'Astuce: activez "Traduction locale (ML Kit)".',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: NLPStatus.failure,
          error: 'Echec de traduction: ${e.toString()}\n'
              'Astuce: activez "Traduction locale (ML Kit)".',
        ),
      );
    }
  }

  Future<void> _onExtractEntities(
    ExtractEntities event,
    Emitter<NLPState> emit,
  ) async {
    emit(
      state.copyWith(
        status: NLPStatus.loading,
        currentOperation: 'Entity Extraction',
      ),
    );

    try {
      final result = event.useLocal
          ? await _repository.extractEntitiesLocal(
              event.text,
              language: event.language,
            )
          : await _repository.extractEntitiesRemote(
              event.text,
              provider: event.provider,
            );

      if (result['success'] == true) {
        emit(state.copyWith(status: NLPStatus.success, result: result));
      } else {
        emit(
          state.copyWith(
            status: NLPStatus.failure,
            error: result['error'] ?? 'Entity extraction failed',
          ),
        );
      }
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: NLPStatus.failure,
          error: _mapDioError(e),
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: NLPStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onSummarizeText(
    SummarizeText event,
    Emitter<NLPState> emit,
  ) async {
    emit(
      state.copyWith(
        status: NLPStatus.loading,
        currentOperation: 'Summarization',
      ),
    );

    try {
      final result = await _repository.summarizeText(
        event.text,
        provider: event.provider,
      );

      if (result['success'] == true) {
        emit(state.copyWith(status: NLPStatus.success, result: result));
      } else {
        emit(
          state.copyWith(
            status: NLPStatus.failure,
            error: result['error'] ?? 'Summarization failed',
          ),
        );
      }
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: NLPStatus.failure,
          error: _mapDioError(e),
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: NLPStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onGenerateSmartReplies(
    GenerateSmartReplies event,
    Emitter<NLPState> emit,
  ) async {
    emit(
      state.copyWith(
        status: NLPStatus.loading,
        currentOperation: 'Smart Reply',
      ),
    );

    try {
      final result = await _repository.generateSmartReplies(event.conversation);

      if (result['success'] == true) {
        emit(state.copyWith(status: NLPStatus.success, result: result));
      } else {
        emit(
          state.copyWith(
            status: NLPStatus.failure,
            error: result['error'] ?? 'Smart reply failed',
          ),
        );
      }
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: NLPStatus.failure,
          error: _mapDioError(e),
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: NLPStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onClassifyText(
    ClassifyText event,
    Emitter<NLPState> emit,
  ) async {
    emit(
      state.copyWith(
        status: NLPStatus.loading,
        currentOperation: 'Classification',
      ),
    );

    try {
      final result = await _repository.classifyText(
        event.text,
        categories: event.categories,
        provider: event.provider,
      );

      if (result['success'] == true) {
        emit(state.copyWith(status: NLPStatus.success, result: result));
      } else {
        emit(
          state.copyWith(
            status: NLPStatus.failure,
            error: result['error'] ?? 'Classification failed',
          ),
        );
      }
    } on DioException catch (e) {
      emit(
        state.copyWith(
          status: NLPStatus.failure,
          error: _mapDioError(e),
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: NLPStatus.failure, error: e.toString()));
    }
  }

  String _mapDioError(DioException e) {
    if (e.response?.statusCode == 401) {
      return _authErrorMessage;
    }
    return e.toString();
  }

  void _onClearResult(ClearNLPResult event, Emitter<NLPState> emit) {
    emit(const NLPState());
  }
}
