import os
import re

file_path = r"C:\Users\DELL\Downloads\GoogleMLKit\frontend\lib\features\generative\pages\chat_page.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

content = re.sub(
    r"_speechToText\.listen\([\s\S]*?localeId:\s*'fr_FR',\s*\);",
    """_speechToText.listen(
        onResult: (result) {
          setState(() {
            final oldText = _messageController.text;
            // Append if not already there or just replace if it's the only thing
            _messageController.text = result.recognizedWords;
            // Move cursor to end
            _messageController.selection = TextSelection.fromPosition(TextPosition(offset: _messageController.text.length));
          });
        },
        localeId: 'fr_FR',
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        listenMode: stt.ListenMode.dictation,
        cancelOnError: true,
        partialResults: true,
      );""",
    content
)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
print("Updated listen method safely")
