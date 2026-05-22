import os

file_path = r"C:\Users\DELL\Downloads\GoogleMLKit\frontend\lib\features\generative\pages\chat_page.dart"

with open(file_path, "r", encoding="utf-8") as f:
    lines = f.readlines()

new_lines = []
for index, line in enumerate(lines):
    new_lines.append(line)
    if "child: Icon(Icons.sentiment_satisfied_alt_rounded," in line:
        has_matched = True

for index in range(len(new_lines)):
    if "child: Icon(Icons.sentiment_satisfied_alt_rounded," in new_lines[index]:
        # Insert 3 lines down
        insert_idx = index + 4
        new_lines.insert(
            insert_idx,
            """                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _toggleListening,
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
                ),\n""",
        )
        break

with open(file_path, "w", encoding="utf-8") as f:
    f.writelines(new_lines)
print("Done")
