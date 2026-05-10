import os

file_path = r"C:\Users\DELL\Downloads\GoogleMLKit\frontend\lib\features\generative\pages\chat_page.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

original_mic_insertion = """                    child: Icon(Icons.sentiment_satisfied_alt_rounded,
                        color: features.generative, size: 22),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container("""

replacement_mic_insertion = """                    child: Icon(Icons.sentiment_satisfied_alt_rounded,
                        color: features.generative, size: 22),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _toggleListening,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _isListening
                          ? Colors.redAccent.withValues(alpha: 0.2)
                          : (Theme.of(context).brightness == Brightness.dark
                              ? DesignColors.backgroundDark
                              : DesignColors.backgroundLight),
                      borderRadius: DesignRadius.radiusXl,
                      border: Border.all(
                          color: (_isListening
                                  ? Colors.redAccent
                                  : (Theme.of(context).brightness == Brightness.dark
                                      ? DesignColors.borderDark
                                      : DesignColors.borderLight))
                              .withValues(alpha: 0.5)),
                    ),
                    child: Icon(
                        _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                        color: _isListening ? Colors.redAccent : Theme.of(context).extension<PremiumTheme>()!.generative,
                        size: 22),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container("""

if original_mic_insertion in content:
    content = content.replace(original_mic_insertion, replacement_mic_insertion)
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)
    print("Mic icon patch successful!")
else:
    print("Target string not found in chat_page.dart.")
