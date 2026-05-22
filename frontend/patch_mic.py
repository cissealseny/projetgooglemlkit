import os

file_path = r"C:\Users\DELL\Downloads\GoogleMLKit\frontend\lib\features\generative\pages\chat_page.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# 1. Add import
if "import 'package:speech_to_text/speech_to_text.dart' as stt;" not in content:
    content = content.replace(
        "import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';",
        "import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';\nimport 'package:speech_to_text/speech_to_text.dart' as stt;",
    )

# 2. Add State Variables
var_block = """class _ChatViewState extends State<_ChatView> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  String _selectedModel = 'ollama:mistral:7b';
  int _nearbyRadiusMeters = 2500;
  bool _isListening = false;
  final stt.SpeechToText _speechToText = stt.SpeechToText();"""

content = content.replace(
    "class _ChatViewState extends State<_ChatView> {\n  final _messageController = TextEditingController();\n  final _scrollController = ScrollController();\n  String _selectedModel = 'ollama:mistral:7b';\n  int _nearbyRadiusMeters = 2500;",
    var_block,
)

# 3. Add _toggleListening Method
toggle_method = """  Future<void> _toggleListening() async {
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
              _messageController.text = result.recognizedWords;
            });
          },
          localeId: 'fr_FR',
        );
      }
    } else {
      setState(() => _isListening = false);
      _speechToText.stop();
    }
  }

  void _scrollToBottom() {"""

content = content.replace("  void _scrollToBottom() {", toggle_method)

# 4. Add the Mic Button
original_mic_insertion = """                    child: Icon(Icons.sentiment_satisfied_alt_rounded,
                        color: features.generative, size: 22),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded("""

replacement_mic_insertion = """                    child: Icon(Icons.sentiment_satisfied_alt_rounded,
                        color: features.generative, size: 22),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: state.status == GenerativeStatus.sending
                      ? null
                      : _toggleListening,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _isListening
                          ? Colors.redAccent.withValues(alpha: 0.2)
                          : (isDark
                              ? DesignColors.backgroundDark
                              : DesignColors.backgroundLight),
                      borderRadius: DesignRadius.radiusXl,
                      border: Border.all(
                          color: (_isListening
                                  ? Colors.redAccent
                                  : (isDark
                                      ? DesignColors.borderDark
                                      : DesignColors.borderLight))
                              .withValues(alpha: 0.5)),
                    ),
                    child: Icon(
                        _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                        color: _isListening ? Colors.redAccent : features.generative,
                        size: 22),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded("""
content = content.replace(original_mic_insertion, replacement_mic_insertion)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
print("Patch successful!")
