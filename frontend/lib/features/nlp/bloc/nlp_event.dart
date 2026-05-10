part of 'nlp_bloc.dart';

abstract class NLPEvent extends Equatable {
  const NLPEvent();

  @override
  List<Object?> get props => [];
}

class AnalyzeSentiment extends NLPEvent {
  final String text;
  final String provider;

  const AnalyzeSentiment({required this.text, this.provider = 'auto'});

  @override
  List<Object> get props => [text, provider];
}

class DetectLanguage extends NLPEvent {
  final String text;
  final bool useLocal;

  const DetectLanguage({required this.text, this.useLocal = true});

  @override
  List<Object> get props => [text, useLocal];
}

class TranslateText extends NLPEvent {
  final String text;
  final String sourceLang;
  final String targetLang;
  final bool useLocal;
  final String provider;

  const TranslateText({
    required this.text,
    this.sourceLang = 'en',
    this.targetLang = 'fr',
    this.useLocal = true,
    this.provider = 'auto',
  });

  @override
  List<Object> get props => [text, sourceLang, targetLang, useLocal, provider];
}

class ExtractEntities extends NLPEvent {
  final String text;
  final bool useLocal;
  final String language;
  final String provider;

  const ExtractEntities({
    required this.text,
    this.useLocal = true,
    this.language = 'en',
    this.provider = 'auto',
  });

  @override
  List<Object> get props => [text, useLocal, language, provider];
}

class SummarizeText extends NLPEvent {
  final String text;
  final String provider;

  const SummarizeText({required this.text, this.provider = 'auto'});

  @override
  List<Object> get props => [text, provider];
}

class ClassifyText extends NLPEvent {
  final String text;
  final List<String> categories;
  final String provider;

  const ClassifyText({
    required this.text,
    this.categories = const <String>[],
    this.provider = 'auto',
  });

  @override
  List<Object> get props => [text, categories, provider];
}

class GenerateSmartReplies extends NLPEvent {
  final List<Map<String, dynamic>> conversation;

  const GenerateSmartReplies({required this.conversation});

  @override
  List<Object> get props => [conversation];
}

class ClearNLPResult extends NLPEvent {}
