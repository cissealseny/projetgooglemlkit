import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:google_mlkit_entity_extraction/google_mlkit_entity_extraction.dart';
import 'package:google_mlkit_smart_reply/google_mlkit_smart_reply.dart';

class MLKitNLPService {
  // Language Identification
  final LanguageIdentifier _languageIdentifier = LanguageIdentifier(
    confidenceThreshold: 0.5,
  );

  // Translation
  OnDeviceTranslator? _translator;
  String? _currentSourceLang;
  String? _currentTargetLang;

  // Entity Extraction
  EntityExtractor? _entityExtractor;

  // Smart Reply
  final SmartReply _smartReply = SmartReply();

  /// Identify language of text
  Future<Map<String, dynamic>> identifyLanguage(String text) async {
    final stopwatch = Stopwatch()..start();

    try {
      final language = await _languageIdentifier.identifyLanguage(text);
      final possibleLanguages =
          await _languageIdentifier.identifyPossibleLanguages(text);

      stopwatch.stop();

      return {
        'success': true,
        'language': language,
        'possibleLanguages': possibleLanguages
            .map(
              (lang) => {
                'language': lang.languageTag,
                'confidence': lang.confidence,
              },
            )
            .toList(),
        'processingTime': stopwatch.elapsedMilliseconds / 1000,
      };
    } catch (e) {
      stopwatch.stop();
      return {
        'success': false,
        'error': e.toString(),
        'processingTime': stopwatch.elapsedMilliseconds / 1000,
      };
    }
  }

  /// Translate text
  Future<Map<String, dynamic>> translateText(
    String text, {
    String sourceLang = 'en',
    String targetLang = 'fr',
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Create new translator if language pair changed
      if (_translator == null ||
          _currentSourceLang != sourceLang ||
          _currentTargetLang != targetLang) {
        _translator?.close();
        _translator = OnDeviceTranslator(
          sourceLanguage: TranslateLanguage.values.firstWhere(
            (l) => l.bcpCode == sourceLang,
            orElse: () => TranslateLanguage.english,
          ),
          targetLanguage: TranslateLanguage.values.firstWhere(
            (l) => l.bcpCode == targetLang,
            orElse: () => TranslateLanguage.french,
          ),
        );
        _currentSourceLang = sourceLang;
        _currentTargetLang = targetLang;
      }

      final translatedText = await _translator!.translateText(text);

      stopwatch.stop();

      return {
        'success': true,
        'originalText': text,
        'translatedText': translatedText,
        'sourceLang': sourceLang,
        'targetLang': targetLang,
        'processingTime': stopwatch.elapsedMilliseconds / 1000,
      };
    } catch (e) {
      stopwatch.stop();
      return {
        'success': false,
        'error': e.toString(),
        'processingTime': stopwatch.elapsedMilliseconds / 1000,
      };
    }
  }

  /// Extract entities from text
  Future<Map<String, dynamic>> extractEntities(
    String text, {
    String language = 'en',
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Create entity extractor for language
      _entityExtractor?.close();
      _entityExtractor = EntityExtractor(
        language: _resolveEntityExtractorLanguage(language),
      );

      final entities = await _entityExtractor!.annotateText(text);

      stopwatch.stop();

      final entityData = entities.map((entity) {
        return {
          'text': entity.text,
          'start': entity.start,
          'end': entity.end,
          'types': entity.entities
              .map((e) => {'type': e.type.name, 'rawValue': e.rawValue})
              .toList(),
        };
      }).toList();

      return {
        'success': true,
        'entities': entityData,
        'count': entities.length,
        'processingTime': stopwatch.elapsedMilliseconds / 1000,
      };
    } catch (e) {
      stopwatch.stop();
      return {
        'success': false,
        'error': e.toString(),
        'processingTime': stopwatch.elapsedMilliseconds / 1000,
      };
    }
  }

  /// Generate smart replies
  Future<Map<String, dynamic>> generateSmartReplies(
    List<Map<String, dynamic>> conversation,
  ) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Clear previous conversation
      _smartReply.clearConversation();

      // Add messages to conversation
      for (final message in conversation) {
        if (message['isLocalUser'] == true) {
          _smartReply.addMessageToConversationFromLocalUser(
            message['text'],
            message['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
          );
        } else {
          _smartReply.addMessageToConversationFromRemoteUser(
            message['text'],
            message['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
            message['userId'] ?? 'remote_user',
          );
        }
      }

      // Generate suggestions
      final result = await _smartReply.suggestReplies();
      final status = result.status.name;
      final mlSuggestions = result.suggestions.toList();

      // Fallback: provide practical replies when ML Kit returns no suggestion.
      final lastRemoteMessage = conversation
          .where((m) => m['isLocalUser'] != true)
          .map((m) => (m['text'] ?? '').toString())
          .where((text) => text.trim().isNotEmpty)
          .lastWhere((_) => true, orElse: () => '');

      final suggestions = mlSuggestions.isNotEmpty
          ? mlSuggestions
          : _buildFallbackReplies(lastRemoteMessage);

      stopwatch.stop();

      String? infoMessage;
      if (result.status ==
          SmartReplySuggestionResultStatus.notSupportedLanguage) {
        infoMessage =
            'Langue non supportee par Smart Reply. Suggestions de secours affichees.';
      } else if (result.status == SmartReplySuggestionResultStatus.noReply) {
        infoMessage =
            'Pas de reponse suggeree pour ce contexte. Suggestions de secours affichees.';
      }

      return {
        'success': true,
        'status': status,
        'suggestions': suggestions,
        'source': mlSuggestions.isNotEmpty ? 'mlkit' : 'fallback',
        if (infoMessage != null) 'info': infoMessage,
        'processingTime': stopwatch.elapsedMilliseconds / 1000,
      };
    } catch (e) {
      stopwatch.stop();
      return {
        'success': false,
        'error': e.toString(),
        'processingTime': stopwatch.elapsedMilliseconds / 1000,
      };
    }
  }

  /// Get supported translation languages
  List<String> getSupportedTranslationLanguages() {
    return TranslateLanguage.values.map((l) => l.bcpCode).toList();
  }

  EntityExtractorLanguage _resolveEntityExtractorLanguage(String language) {
    final normalized = language.toLowerCase().trim();

    const codeToName = {
      'en': 'english',
      'fr': 'french',
      'de': 'german',
      'es': 'spanish',
      'it': 'italian',
      'pt': 'portuguese',
    };

    final target = codeToName[normalized] ?? normalized;

    return EntityExtractorLanguage.values.firstWhere(
      (l) => l.name.toLowerCase() == target,
      orElse: () => EntityExtractorLanguage.english,
    );
  }

  List<String> _buildFallbackReplies(String remoteMessage) {
    if (remoteMessage.trim().isEmpty) {
      return const [
        'Merci pour votre message. Pouvez-vous donner plus de details ?',
        'Je comprends. Depuis quand ce probleme apparait-il ?',
        'Pouvez-vous partager une capture d ecran ou le message d erreur ?',
      ];
    }

    final normalized = remoteMessage.toLowerCase();
    final isFrench = RegExp(
            r'\b(bonjour|merci|probleme|application|photo|camera|aide|pouvez-vous|ouvre|plante)\b')
        .hasMatch(normalized);

    if (isFrench) {
      if (normalized.contains('camera') || normalized.contains('photo')) {
        return const [
          'Merci pour votre retour. Pouvez-vous partager la version Android ?',
          'Essayez de redemarrer l application puis testez la camera a nouveau.',
          'Nous analysons ce bug et revenons vers vous rapidement.',
        ];
      }

      return const [
        'Merci pour votre message. Pouvez-vous donner plus de details ?',
        'Je comprends. Pouvez-vous preciser les etapes pour reproduire le probleme ?',
        'Merci, nous verifions cela et revenons vers vous rapidement.',
      ];
    }

    if (normalized.contains('camera') || normalized.contains('crash')) {
      return const [
        'Thanks for reporting this. Could you share your Android version?',
        'Please restart the app and try opening the camera again.',
        'We are investigating this issue and will get back to you shortly.',
      ];
    }

    return const [
      'Thanks for your message. Could you share more details?',
      'I understand. Could you list the steps to reproduce this issue?',
      'Thanks, we are checking this and will get back to you shortly.',
    ];
  }

  /// Dispose all services
  void dispose() {
    _languageIdentifier.close();
    _translator?.close();
    _entityExtractor?.close();
    _smartReply.close();
  }
}
