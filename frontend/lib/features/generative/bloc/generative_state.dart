part of 'generative_bloc.dart';

enum GenerativeStatus {
  initial,
  loading,
  sending,
  generating,
  success,
  failure,
}

enum QuizFlowStatus {
  initial,
  loading,
  active,
  grading,
  completed,
  failure,
}

class GenerativeState extends Equatable {
  final GenerativeStatus status;
  final List<dynamic> conversations;
  final Map<String, dynamic>? currentConversation;
  final List<dynamic> messages;
  final String? generatedContent;
  final String? error;
  final String? currentOperation;
  final Quiz? activeQuiz;
  final QuizFlowStatus quizStatus;
  final Map<int, String> quizAnswers;
  final int quizQuestionIndex;
  final QuizResult? quizResult;
  final String? quizError;

  const GenerativeState({
    this.status = GenerativeStatus.initial,
    this.conversations = const [],
    this.currentConversation,
    this.messages = const [],
    this.generatedContent,
    this.error,
    this.currentOperation,
    this.activeQuiz,
    this.quizStatus = QuizFlowStatus.initial,
    this.quizAnswers = const {},
    this.quizQuestionIndex = 0,
    this.quizResult,
    this.quizError,
  });

  GenerativeState copyWith({
    GenerativeStatus? status,
    List<dynamic>? conversations,
    Map<String, dynamic>? currentConversation,
    List<dynamic>? messages,
    String? generatedContent,
    String? error,
    String? currentOperation,
    Quiz? activeQuiz,
    QuizFlowStatus? quizStatus,
    Map<int, String>? quizAnswers,
    int? quizQuestionIndex,
    QuizResult? quizResult,
    String? quizError,
    // Flags pour remettre les champs nullable à null explicitement
    bool clearActiveQuiz = false,
    bool clearQuizResult = false,
    bool clearGeneratedContent = false,
    bool clearError = false,
    bool clearQuizError = false,
  }) {
    return GenerativeState(
      status: status ?? this.status,
      conversations: conversations ?? this.conversations,
      currentConversation: currentConversation ?? this.currentConversation,
      messages: messages ?? this.messages,
      // ✅ Respect du fallback + possibilité de reset explicite
      generatedContent: clearGeneratedContent
          ? null
          : (generatedContent ?? this.generatedContent),
      error: clearError ? null : (error ?? this.error),
      currentOperation: currentOperation ?? this.currentOperation,
      activeQuiz: clearActiveQuiz ? null : (activeQuiz ?? this.activeQuiz),
      quizStatus: quizStatus ?? this.quizStatus,
      quizAnswers: quizAnswers ?? this.quizAnswers,
      quizQuestionIndex: quizQuestionIndex ?? this.quizQuestionIndex,
      quizResult: clearQuizResult ? null : (quizResult ?? this.quizResult),
      quizError: clearQuizError ? null : (quizError ?? this.quizError),
    );
  }

  @override
  List<Object?> get props => [
        status,
        conversations,
        currentConversation,
        messages,
        generatedContent,
        error,
        currentOperation,
        activeQuiz,
        quizStatus,
        quizAnswers,
        quizQuestionIndex,
        quizResult,
        quizError,
      ];
}
