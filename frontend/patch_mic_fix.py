import os

file_path = r"C:\Users\DELL\Downloads\GoogleMLKit\frontend\lib\features\generative\pages\chat_page.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

old_listen = """        if (available) {
          setState(() => _isListening = true);
          _speechToText.listen(
            onResult: (result) {
              setState(() {
                _messageController.text = result.recognizedWords;
              });
            },
            localeId: 'fr_FR',
          );
        }"""

new_listen = """        if (available) {
          setState(() => _isListening = true);
          _speechToText.listen(
            onResult: (result) {
              print('Speech snippet: ${result.recognizedWords}');
              setState(() {
                _messageController.text = result.recognizedWords;
              });
            },
            localeId: 'fr_FR',
            listenFor: const Duration(seconds: 30),
            pauseFor: const Duration(seconds: 5),
            partialResults: true,
          );
        }"""

content = content.replace(old_listen, new_listen)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
print("Updated listen method")
