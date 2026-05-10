part of 'generative_bloc.dart';

enum GenerativeStatus {
  initial,
  loading,
  sending,
  generating,
  success,
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

  const GenerativeState({
    this.status = GenerativeStatus.initial,
    this.conversations = const [],
    this.currentConversation,
    this.messages = const [],
    this.generatedContent,
    this.error,
    this.currentOperation,
  });

  GenerativeState copyWith({
    GenerativeStatus? status,
    List<dynamic>? conversations,
    Map<String, dynamic>? currentConversation,
    List<dynamic>? messages,
    String? generatedContent,
    String? error,
    String? currentOperation,
  }) {
    return GenerativeState(
      status: status ?? this.status,
      conversations: conversations ?? this.conversations,
      currentConversation: currentConversation ?? this.currentConversation,
      messages: messages ?? this.messages,
      generatedContent: generatedContent,
      error: error,
      currentOperation: currentOperation ?? this.currentOperation,
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
  ];
}
