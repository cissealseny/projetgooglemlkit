import os
import re

file_path = r"C:\Users\DELL\Downloads\GoogleMLKit\frontend\lib\features\generative\pages\chat_page.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace("listenMode: stt.ListenMode.dictation,", "listenOptions: stt.SpeechListenOptions(listenMode: stt.ListenMode.dictation, cancelOnError: true, partialResults: true),")
content = content.replace("cancelOnError: true,", "")
content = content.replace("partialResults: true,", "")
content = content.replace("final oldText = _messageController.text;", "final oldText = _messageController.text; // ignore_for_file: unused_local_variable")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
print("Updated API syntax")
