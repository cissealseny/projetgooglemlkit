import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/di/injection.dart';
import '../../../core/theme/design_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/premium_theme.dart';
import '../bloc/generative_bloc.dart';

/// Premium Chat Page
class ChatPage extends StatelessWidget {
  final bool isBottomSheet;
  const ChatPage({super.key, this.isBottomSheet = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GenerativeBloc>(
      create: (_) => getIt<GenerativeBloc>()..add(const CreateConversation()),
      child: _ChatView(isBottomSheet: isBottomSheet),
    );
  }
}

class _ChatView extends StatefulWidget {
  final bool isBottomSheet;
  const _ChatView({this.isBottomSheet = false});

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  String _selectedModel = 'ollama:mistral:7b';
  int _nearbyRadiusMeters = 2500;
  bool _isListening = false;
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  final _models = [
    {
      'id': 'ollama:mistral:7b',
      'name': '🚀 Mistral 7B (Local)',
      'icon': Icons.rocket_launch_rounded
    },
    {
      'id': 'ollama:llama3.2:1b',
      'name': '🦙 Llama 3.2 (Léger)',
      'icon': Icons.computer_rounded
    },
    {
      'id': 'gemini:gemini-2.0-flash',
      'name': '✨ Gemini 2.0 Flash',
      'icon': Icons.auto_awesome_rounded
    },
    {
      'id': 'gemini:gemini-2.5-pro',
      'name': '⭐ Gemini 2.5 Pro',
      'icon': Icons.star_rounded
    },
    {
      'id': 'gpt:gpt-4o-mini',
      'name': '⚡ GPT-4o Mini',
      'icon': Icons.bolt_rounded
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final features = Theme.of(context).extension<FeatureColors>()!;

    return Scaffold(
      resizeToAvoidBottomInset: !widget.isBottomSheet,
      body: Column(
        children: [
          _buildHeader(isDark, features),
          Expanded(
            child: BlocConsumer<GenerativeBloc, GenerativeState>(
              listener: (context, state) {
                if (state.status == GenerativeStatus.failure &&
                    state.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.error!)),
                  );
                }
                if (state.messages.isNotEmpty) _scrollToBottom();
              },
              builder: (context, state) {
                return Column(
                  children: [
                    Expanded(
                      child: state.messages.isEmpty
                          ? _buildEmptyState(isDark, features)
                          : ListView.builder(
                              controller: _scrollController,
                              padding: EdgeInsets.fromLTRB(16, 16, 16,
                                  DesignSpacing.bottomNavHeight + 100),
                              itemCount: state.messages.length,
                              itemBuilder: (context, index) {
                                final raw = state.messages[index];
                                final message = raw is Map
                                    ? Map<String, dynamic>.from(raw)
                                    : <String, dynamic>{};
                                final isUser = message['role'] == 'user';
                                return _MessageBubble(
                                    messageData: message,
                                    isUser: isUser,
                                    color: features.generative);
                              },
                            ),
                    ),
                    if (state.status == GenerativeStatus.sending)
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _TypingIndicator(color: features.generative)),
                    _buildInputBar(state, isDark, features),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, FeatureColors features) {
    return Container(
      decoration: BoxDecoration(gradient: DesignColors.generativeGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
          child: Row(
            children: [
              if (Navigator.canPop(context)) ...[
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(width: 8),
              ] else ...[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: DesignRadius.radiusMd),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Assistant IA',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DesignTypography.titleLarge(Colors.white)),
                      Text(
                          'Guide Eco-smart • ${_models.firstWhere((m) => m['id'] == _selectedModel)['name']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DesignTypography.bodySmall(
                              Colors.white.withValues(alpha: 0.8))),
                    ]),
              ),
              _ModelSelector(
                  models: _models,
                  selected: _selectedModel,
                  onChanged: (v) => setState(() => _selectedModel = v)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, FeatureColors features) {
    final titleColor =
        isDark ? DesignColors.textPrimaryDark : DesignColors.textPrimaryLight;
    final subtitleColor = isDark
        ? DesignColors.textSecondaryDark
        : DesignColors.textSecondaryLight;

    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                        gradient: DesignColors.generativeGradient,
                        borderRadius: DesignRadius.radiusXl),
                    child: const Icon(Icons.auto_awesome_rounded,
                        size: 34, color: Colors.white),
                  ),
                  const SizedBox(height: 18),
                  Text('Je vous guide dans Eco-smart',
                      style: DesignTypography.headlineMedium(titleColor),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    'Posez-moi une question sur les pages, les scans, les collectes, les centres, le quiz ou vos statistiques.',
                    style: DesignTypography.bodyMedium(subtitleColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _SuggestionChip(
                          label: 'Scanner un déchet',
                          color: features.generative,
                          onTap: () => _setMessage(
                              'Comment scanner un déchet dans l\'application ?')),
                      _SuggestionChip(
                          label: 'Mes statistiques',
                          color: features.generative,
                          onTap: () => _setMessage(
                              'Où puis-je voir mes statistiques et mon impact ?')),
                      _SuggestionChip(
                          label: 'Nouvelle collecte',
                          color: features.generative,
                          onTap: () => _setMessage(
                              'Comment enregistrer une nouvelle collecte ?')),
                      _SuggestionChip(
                          label: 'Centres proches',
                          color: features.generative,
                          onTap: () => _setMessage(
                              'Comment trouver un centre de collecte proche ?')),
                      _SuggestionChip(
                          label: 'Eco-smart',
                          color: features.generative,
                          onTap: () => _setMessage(
                              'Explique-moi les principales parties de l\'application Eco-smart.')),
                      _SuggestionChip(
                          label: 'Eco-Quiz',
                          color: features.generative,
                          onTap: () => _setMessage('/quiz écologie')),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required double size,
    required VoidCallback? onTap,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ??
              (isDark
                  ? DesignColors.backgroundDark
                  : DesignColors.backgroundLight),
          borderRadius: DesignRadius.radiusXl,
          border: Border.all(
              color: (borderColor ??
                      (isDark
                          ? DesignColors.borderDark
                          : DesignColors.borderLight))
                  .withValues(alpha: 0.5)),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
    );
  }

  Widget _buildInputBar(
      GenerativeState state, bool isDark, FeatureColors features) {
    final double bottomPadding = widget.isBottomSheet
        ? MediaQuery.of(context).viewPadding.bottom + 16
        : DesignSpacing.bottomNavHeight + 16;
    final compact = MediaQuery.of(context).size.width < 390;
    final toolSize = compact ? 40.0 : 46.0;
    final horizontalGap = compact ? 6.0 : 8.0;
    final inputPadding = compact ? 14.0 : 18.0;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? DesignColors.surfaceDark : DesignColors.surfaceLight,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Flexible(
                child: GestureDetector(
                  onTap: _showNearbySettings,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: features.generative.withValues(alpha: 0.12),
                      borderRadius: DesignRadius.radiusXl,
                      border: Border.all(
                          color: features.generative.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.radar_rounded,
                            size: 16, color: features.generative),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Rayon ${(_nearbyRadiusMeters / 1000).toStringAsFixed(1)} km',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _showNearbySettings,
                tooltip: 'Regler',
                icon: const Icon(Icons.tune_rounded, size: 18),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildToolButton(
                icon: Icons.camera_alt_rounded,
                iconColor: features.generative,
                isDark: isDark,
                size: toolSize,
                onTap: state.status == GenerativeStatus.sending
                    ? null
                    : () => _pickAndLabelImage(state),
              ),
              SizedBox(width: horizontalGap),
              _buildToolButton(
                icon: Icons.document_scanner_rounded,
                iconColor: features.generative,
                isDark: isDark,
                size: toolSize,
                onTap: state.status == GenerativeStatus.sending
                    ? null
                    : () => _pickAndRecognizeText(state),
              ),
              SizedBox(width: horizontalGap),
              _buildToolButton(
                icon: _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                iconColor:
                    _isListening ? Colors.redAccent : features.generative,
                isDark: isDark,
                size: toolSize,
                onTap: _toggleListening,
                backgroundColor: _isListening
                    ? Colors.redAccent.withValues(alpha: 0.2)
                    : null,
                borderColor: _isListening ? Colors.redAccent : null,
              ),
              SizedBox(width: horizontalGap),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? DesignColors.backgroundDark
                        : DesignColors.backgroundLight,
                    borderRadius: DesignRadius.radiusXl,
                    border: Border.all(
                        color: (isDark
                                ? DesignColors.borderDark
                                : DesignColors.borderLight)
                            .withValues(alpha: 0.5)),
                  ),
                  child: TextField(
                    controller: _messageController,
                    style: DesignTypography.bodyMedium(isDark
                        ? DesignColors.textPrimaryDark
                        : DesignColors.textPrimaryLight),
                    decoration: InputDecoration(
                      hintText: state.quizStatus == QuizFlowStatus.active
                          ? 'Reponse au quiz...'
                          : 'Ecrivez votre message...',
                      hintStyle: DesignTypography.bodyMedium(isDark
                          ? DesignColors.textTertiaryDark
                          : DesignColors.textTertiaryLight),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: inputPadding, vertical: 14),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(state),
                  ),
                ),
              ),
              SizedBox(width: compact ? 8 : 10),
              GestureDetector(
                onTap: state.status == GenerativeStatus.sending
                    ? null
                    : () => _sendMessage(state),
                child: Container(
                  width: toolSize,
                  height: toolSize,
                  decoration: BoxDecoration(
                    gradient: state.status == GenerativeStatus.sending
                        ? null
                        : DesignColors.generativeGradient,
                    color: state.status == GenerativeStatus.sending
                        ? (isDark
                            ? DesignColors.textTertiaryDark
                            : DesignColors.textTertiaryLight)
                        : null,
                    borderRadius: DesignRadius.radiusMd,
                  ),
                  child: state.status == GenerativeStatus.sending
                      ? const Center(
                          child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white)))
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _setMessage(String message) => _messageController.text = message;

  Future<void> _pickAndLabelImage(GenerativeState state) async {
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(source: ImageSource.camera);
      if (xFile == null) return;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Analyse des ingrédients via ML Kit...')),
      );

      final inputImage = InputImage.fromFilePath(xFile.path);
      final labeler =
          ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.65));
      final labels = await labeler.processImage(inputImage);
      labeler.close();

      if (!mounted) return;
      if (labels.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Aucun ingrédient clair n'a été détecté.")),
        );
        return;
      }

      final labelNames = labels.map((l) => l.label).join(', ');
      final prompt =
          "J'ai pris cet objet en photo et voici ce que l'IA a détecté : $labelNames. "
          "Comment puis-je trier ou recycler cet objet correctement en Tunisie, ou quelles idées d'upcycling créatives as-tu pour le valoriser chez moi ?";

      _messageController.text = prompt;
      _sendMessage(state);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur ML Kit Vision : $e')),
      );
    }
  }

  Future<void> _pickAndRecognizeText(GenerativeState state) async {
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(source: ImageSource.camera);
      if (xFile == null) return;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Reconnaissance du texte en cours (OCR)...')),
      );

      final inputImage = InputImage.fromFilePath(xFile.path);
      final textRecognizer =
          TextRecognizer(script: TextRecognitionScript.latin);
      final recognizedText = await textRecognizer.processImage(inputImage);
      textRecognizer.close();

      if (!mounted) return;
      if (recognizedText.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Aucun texte n'a été détecté dans l'image.")),
        );
        return;
      }

      final prompt =
          "Voici un texte que je viens de scanner avec l'OCR local de ML Kit :\n\n"
          "\"${recognizedText.text}\"\n\n"
          "Peux-tu m'expliquer ce texte simplement ou m'en faire un résumé clair ?";

      _messageController.text = prompt;
      _sendMessage(state);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur ML Kit OCR : $e')),
      );
    }
  }

  Future<void> _sendMessage(GenerativeState state) async {
    if (_messageController.text.isNotEmpty &&
        state.currentConversation != null) {
      HapticFeedback.lightImpact();
      final prompt = _messageController.text.trim();

      if (_handleQuizCommand(state, prompt)) {
        _messageController.clear();
        return;
      }

      if (state.quizStatus == QuizFlowStatus.active) {
        context.read<GenerativeBloc>().add(AnswerQuizQuestion(answer: prompt));
        _messageController.clear();
        return;
      }

      double? latitude;
      double? longitude;

      if (_seemsNearbyPlacesPrompt(prompt)) {
        final coords = await _resolveUserCoordinates();
        latitude = coords?.$1;
        longitude = coords?.$2;
      }

      if (!mounted) return;
      context.read<GenerativeBloc>().add(
            SendMessage(
                conversationId: state.currentConversation!['id'],
                message: prompt,
                model: _selectedModel,
                latitude: latitude,
                longitude: longitude,
                radiusMeters: _seemsNearbyPlacesPrompt(prompt)
                    ? _nearbyRadiusMeters
                    : null),
          );
      _messageController.clear();
    }
  }

  bool _handleQuizCommand(GenerativeState state, String prompt) {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) return false;

    final lower = trimmed.toLowerCase();
    final isQuizCommand = lower.startsWith('/quiz') ||
        lower.startsWith('quiz:') ||
        lower.startsWith('quiz ');
    if (!isQuizCommand) return false;

    if (lower.startsWith('/quiz stop') || lower.startsWith('/quiz cancel')) {
      context.read<GenerativeBloc>().add(CancelQuizSession());
      return true;
    }

    String topic = trimmed;
    if (lower.startsWith('/quiz')) {
      topic = trimmed.substring(5).trim();
    } else if (lower.startsWith('quiz:')) {
      topic = trimmed.substring(5).trim();
    } else if (lower.startsWith('quiz ')) {
      topic = trimmed.substring(5).trim();
    }

    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indique un sujet apres /quiz.')),
      );
      return true;
    }

    context.read<GenerativeBloc>().add(
          StartQuizSession(
            topic: topic,
            questionCount: 6,
            difficulty: 'medium',
            formats: const ['mcq', 'true_false', 'open'],
            language: 'auto',
            model: _selectedModel,
          ),
        );
    return true;
  }

  void _showNearbySettings() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        double localRadius = _nearbyRadiusMeters.toDouble();
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recherche de lieux proches',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Rayon actuel: ${(localRadius / 1000).toStringAsFixed(1)} km',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Slider(
                    value: localRadius,
                    min: 500,
                    max: 10000,
                    divisions: 19,
                    label: '${(localRadius / 1000).toStringAsFixed(1)} km',
                    onChanged: (value) {
                      setModalState(() => localRadius = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(
                            () => _nearbyRadiusMeters = localRadius.round());
                        Navigator.of(context).pop();
                      },
                      child: const Text('Appliquer'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  bool _seemsNearbyPlacesPrompt(String message) {
    final text = message.toLowerCase();
    return text.contains('proche') ||
        text.contains('près') ||
        text.contains('pres') ||
        text.contains('autour') ||
        text.contains('nearby') ||
        text.contains('restaurant') ||
        text.contains('cafe') ||
        text.contains('café') ||
        text.contains('hotel') ||
        text.contains('hôtel') ||
        text.contains('cuisine') ||
        text.contains('manger') ||
        text.contains('repas') ||
        text.contains('fast food') ||
        text.contains('fastfood') ||
        text.contains('snack') ||
        text.contains('dejeuner') ||
        text.contains('déjeuner') ||
        text.contains('diner') ||
        text.contains('dîner');
  }

  Future<(double, double)?> _resolveUserCoordinates() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationInfo(
          'Activez la localisation pour des suggestions proches de vous.');
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showLocationInfo(
          'Permission localisation refusee: reponse sans geolocalisation precise.');
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      return (position.latitude, position.longitude);
    } catch (_) {
      _showLocationInfo('Impossible de recuperer la position actuelle.');
      return null;
    }
  }

  void _showLocationInfo(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _toggleListening() async {
    if (!_isListening) {
      bool available = await _speechToText.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (errorNotification) {
          print('Speech recognition error: $errorNotification');
          setState(() => _isListening = false);
        },
      );
      if (available) {
        setState(() => _isListening = true);
        _speechToText.listen(
          onResult: (result) {
            setState(() {
              final oldText = _messageController
                  .text; // ignore_for_file: unused_local_variable
              // Append if not already there or just replace if it's the only thing
              _messageController.text = result.recognizedWords;
              // Move cursor to end
              _messageController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _messageController.text.length));
            });
          },
          localeId: 'fr_FR',
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 5),
          listenOptions: stt.SpeechListenOptions(
              listenMode: stt.ListenMode.dictation, partialResults: true),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speechToText.stop();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: DesignDurations.normal, curve: Curves.easeOut);
      }
    });
  }
}

class _ModelSelector extends StatelessWidget {
  final List<Map<String, dynamic>> models;
  final String selected;
  final ValueChanged<String> onChanged;
  const _ModelSelector(
      {required this.models, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: DesignRadius.radiusMd),
      itemBuilder: (context) => models
          .map((m) => PopupMenuItem(
                value: m['id'] as String,
                child: Row(children: [
                  Icon(m['icon'] as IconData,
                      size: 20,
                      color:
                          selected == m['id'] ? DesignColors.generative : null),
                  const SizedBox(width: 12),
                  Text(m['name'] as String),
                  const Spacer(),
                  if (selected == m['id'])
                    const Icon(Icons.check_rounded,
                        size: 18, color: DesignColors.generative),
                ]),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: DesignRadius.radiusMd),
        child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> messageData;
  final bool isUser;
  final Color color;
  const _MessageBubble(
      {required this.messageData, required this.isUser, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final message = (messageData['content'] ?? '').toString();
    final places = (messageData['places'] is List)
        ? List<Map<String, dynamic>>.from(
            (messageData['places'] as List)
                .where((e) => e is Map)
                .map((e) => Map<String, dynamic>.from(e as Map)),
          )
        : const <Map<String, dynamic>>[];
    final center = (messageData['map_center'] is Map)
        ? Map<String, dynamic>.from(messageData['map_center'] as Map)
        : <String, dynamic>{};

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          gradient: isUser ? DesignColors.generativeGradient : null,
          color: isUser
              ? null
              : (isDark ? DesignColors.surfaceDark : DesignColors.surfaceLight),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          boxShadow: DesignColors.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(message,
                style: DesignTypography.bodyMedium(isUser
                    ? Colors.white
                    : (isDark
                        ? DesignColors.textPrimaryDark
                        : DesignColors.textPrimaryLight))),
            if (!isUser && places.isNotEmpty) ...[
              const SizedBox(height: 12),
              _PlacesMapSection(
                places: places,
                center: center,
                color: color,
                isDark: isDark,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlacesMapSection extends StatefulWidget {
  final List<Map<String, dynamic>> places;
  final Map<String, dynamic> center;
  final Color color;
  final bool isDark;

  const _PlacesMapSection({
    required this.places,
    required this.center,
    required this.color,
    required this.isDark,
  });

  @override
  State<_PlacesMapSection> createState() => _PlacesMapSectionState();
}

class _PlacesMapSectionState extends State<_PlacesMapSection> {
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final categories = _extractCategories(widget.places);
    final filteredPlaces = _filterPlaces(widget.places, _selectedCategory);
    final mappablePlaces = filteredPlaces
        .where((place) =>
            _extractLatitude(place) != null && _extractLongitude(place) != null)
        .toList();
    final visiblePlaces = mappablePlaces.take(3).toList();

    final firstPlace = visiblePlaces.isNotEmpty
        ? visiblePlaces.first
        : (filteredPlaces.isNotEmpty
            ? filteredPlaces.first
            : const <String, dynamic>{});
    final centerLat =
        _extractLatitude(widget.center) ?? _extractLatitude(firstPlace) ?? 0;
    final centerLng =
        _extractLongitude(widget.center) ?? _extractLongitude(firstPlace) ?? 0;

    final markers = <Marker>{};
    for (var i = 0; i < visiblePlaces.length; i++) {
      final place = visiblePlaces[i];
      final lat = _extractLatitude(place);
      final lng = _extractLongitude(place);
      final rawId = (place['id'] ?? '').toString().trim();
      final fallbackId =
          '${place['name'] ?? 'place'}_${lat ?? 0}_${lng ?? 0}_$i';
      final id = rawId.isNotEmpty ? rawId : fallbackId;
      if (lat == null || lng == null) continue;

      markers.add(
        Marker(
          markerId: MarkerId(id),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: (place['name'] ?? '').toString(),
            snippet: (place['address'] ?? '').toString(),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lieux proches trouves (${visiblePlaces.length})',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: widget.isDark
                    ? DesignColors.textPrimaryDark
                    : DesignColors.textPrimaryLight,
              ),
        ),
        if (categories.length > 1) ...[
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((category) {
                final selected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_categoryLabel(category)),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _selectedCategory = category);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        const SizedBox(height: 8),
        if (!kIsWeb && centerLat != 0 && centerLng != 0)
          ClipRRect(
            borderRadius: DesignRadius.radiusMd,
            child: SizedBox(
              height: 190,
              width: double.infinity,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(centerLat, centerLng),
                  zoom: 14.0,
                ),
                markers: markers,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),
            ),
          ),
        if (filteredPlaces.isNotEmpty && visiblePlaces.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'Aucun des lieux retournes ne contient des coordonnees exploitables.',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        const SizedBox(height: 8),
        ...visiblePlaces.map((place) {
          final rating = place['rating'];
          final ratingsTotal = place['user_ratings_total'];
          final distanceText = _distanceLabel(place['distance_meters']);
          final photoUrl = _resolvePlaceImage(place);
          final category = _normalizeCategory(place['place_type']);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: DesignRadius.radiusMd,
              color: widget.color.withValues(alpha: 0.08),
              border: Border.all(color: widget.color.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (photoUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: DesignRadius.radiusMd,
                    child: Image.network(
                      photoUrl,
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 130,
                        width: double.infinity,
                        color: Colors.black12,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  (place['name'] ?? '').toString(),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  (place['address'] ?? '').toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Note: ${rating ?? 'N/A'} (${ratingsTotal ?? 0} avis)',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                if (distanceText != null)
                  Text(
                    'Distance: $distanceText',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                if (category != 'all')
                  Text(
                    'Categorie: ${_categoryLabel(category)}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _openInMaps(context, place['maps_url']),
                    icon: const Icon(Icons.map_rounded, size: 16),
                    label: const Text('Ouvrir dans Google Maps'),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  double? _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse((value ?? '').toString());
  }

  double? _extractLatitude(Map<String, dynamic> source) {
    final location = source['location'];
    return _toDouble(source['latitude']) ??
        _toDouble(source['lat']) ??
        (location is Map ? _toDouble(location['lat']) : null);
  }

  double? _extractLongitude(Map<String, dynamic> source) {
    final location = source['location'];
    return _toDouble(source['longitude']) ??
        _toDouble(source['lng']) ??
        (location is Map ? _toDouble(location['lng']) : null);
  }

  String? _distanceLabel(dynamic meters) {
    final distance = _toDouble(meters);
    if (distance == null) return null;
    if (distance < 1000) return '${distance.toStringAsFixed(0)} m';
    return '${(distance / 1000).toStringAsFixed(1)} km';
  }

  String _resolvePlaceImage(Map<String, dynamic> place) {
    final thumb = (place['thumbnail_proxy_url'] ?? '').toString().trim();
    if (thumb.isNotEmpty) return thumb;
    return (place['photo_proxy_url'] ?? '').toString().trim();
  }

  List<String> _extractCategories(List<Map<String, dynamic>> source) {
    final set = <String>{'all'};
    for (final place in source) {
      set.add(_normalizeCategory(place['place_type']));
    }
    return set.toList();
  }

  List<Map<String, dynamic>> _filterPlaces(
    List<Map<String, dynamic>> source,
    String category,
  ) {
    if (category == 'all') return source;
    return source
        .where((p) => _normalizeCategory(p['place_type']) == category)
        .toList();
  }

  String _normalizeCategory(dynamic raw) {
    final value = (raw ?? '').toString().trim().toLowerCase();
    if (value.isEmpty) return 'other';
    return value;
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'all':
        return 'Tous';
      case 'restaurant':
        return 'Restaurant';
      case 'cafe':
        return 'Cafe';
      case 'lodging':
        return 'Hotel';
      case 'bar':
        return 'Bar';
      case 'tourist_attraction':
        return 'Attraction';
      default:
        return category;
    }
  }

  Future<void> _openInMaps(BuildContext context, dynamic urlValue) async {
    final raw = (urlValue ?? '').toString().trim();
    if (raw.isEmpty) return;
    final uri = Uri.tryParse(raw);
    if (uri == null) return;

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d ouvrir Google Maps.')),
      );
    }
  }
}

class _TypingIndicator extends StatefulWidget {
  final Color color;
  const _TypingIndicator({required this.color});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
            color:
                isDark ? DesignColors.surfaceDark : DesignColors.surfaceLight,
            borderRadius: DesignRadius.radiusLg,
            boxShadow: DesignColors.shadowSm),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final delay = i * 0.2;
              final value = ((_controller.value + delay) % 1.0);
              final scale = 0.5 + (0.5 * (1 - (2 * value - 1).abs()));
              return Container(
                margin: EdgeInsets.only(left: i > 0 ? 4 : 0),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: scale),
                    shape: BoxShape.circle),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SuggestionChip(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: DesignRadius.radiusXl,
            border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Text(label, style: DesignTypography.labelMedium(color)),
      ),
    );
  }
}
