part of 'generative_bloc.dart';

abstract class GenerativeEvent extends Equatable {
  const GenerativeEvent();

  @override
  List<Object?> get props => [];
}

class LoadConversations extends GenerativeEvent {}

class CreateConversation extends GenerativeEvent {
  final String? title;

  const CreateConversation({this.title});

  @override
  List<Object?> get props => [title];
}

class SelectConversation extends GenerativeEvent {
  final int conversationId;

  const SelectConversation({required this.conversationId});

  @override
  List<Object> get props => [conversationId];
}

class DeleteConversation extends GenerativeEvent {
  final int conversationId;

  const DeleteConversation({required this.conversationId});

  @override
  List<Object> get props => [conversationId];
}

class SendMessage extends GenerativeEvent {
  final int conversationId;
  final String message;
  final String model;
  final double? latitude;
  final double? longitude;
  final int? radiusMeters;

  const SendMessage({
    required this.conversationId,
    required this.message,
    this.model = 'ollama:mistral:7b',
    this.latitude,
    this.longitude,
    this.radiusMeters,
  });

  @override
  List<Object?> get props =>
      [conversationId, message, model, latitude, longitude, radiusMeters];
}

class GenerateText extends GenerativeEvent {
  final String prompt;
  final String model;
  final double temperature;

  const GenerateText({
    required this.prompt,
    this.model = 'gemini',
    this.temperature = 0.7,
  });

  @override
  List<Object> get props => [prompt, model, temperature];
}

class GenerateCode extends GenerativeEvent {
  final String prompt;
  final String language;

  const GenerateCode({required this.prompt, this.language = 'python'});

  @override
  List<Object> get props => [prompt, language];
}

class ClearGenerativeResult extends GenerativeEvent {}

class StartQuizSession extends GenerativeEvent {
  final String topic;
  final int questionCount;
  final String difficulty;
  final List<String> formats;
  final String language;
  final String model;

  const StartQuizSession({
    required this.topic,
    this.questionCount = 6,
    this.difficulty = 'medium',
    this.formats = const ['mcq', 'true_false', 'open'],
    this.language = 'auto',
    this.model = 'ollama:mistral:7b',
  });

  @override
  List<Object?> get props =>
      [topic, questionCount, difficulty, formats, language, model];
}

class AnswerQuizQuestion extends GenerativeEvent {
  final String answer;

  const AnswerQuizQuestion({required this.answer});

  @override
  List<Object?> get props => [answer];
}

class CancelQuizSession extends GenerativeEvent {}
