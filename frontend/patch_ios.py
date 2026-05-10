import os

file_path = r"C:\Users\DELL\Downloads\GoogleMLKit\frontend\ios\Runner\Info.plist"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

permissions = """        <key>NSSpeechRecognitionUsageDescription</key>
        <string>Permettre à l'application de reconnaître votre voix pour envoyer des messages.</string>
        <key>NSMicrophoneUsageDescription</key>
        <string>Nous avons besoin d'accéder au microphone pour enregistrer les mémos vocaux.</string>
</dict>"""

if "NSSpeech" not in content:
    content = content.replace("</dict>", permissions)
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)
print("Done")
