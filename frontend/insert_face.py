with open(r"c:\Users\DELL\Downloads\GoogleMLKit\frontend\lib\features\generative\pages\chat_page.dart", "r", encoding="utf-8") as f:
    text = f.read()

old = """      String emotionDescription = "neutre";
      if (isSmiling && bothEyesOpen) emotionDescription = "très heureux(se)";
      else if (isSmiling) emotionDescription = "souriant(e)";
      else if (!bothEyesOpen) emotionDescription = "fatigué(e) ou avec les yeux fermés";"""

new = """      String emotionDescription = "neutre";
      if (isSmiling && bothEyesOpen) {
        emotionDescription = "très heureux(se)";
      } else if (isSmiling) {
        emotionDescription = "souriant(e)";
      } else if (!bothEyesOpen) {
        emotionDescription = "fatigué(e) ou avec les yeux fermés";
      }"""

text = text.replace(old, new)
with open(r"c:\Users\DELL\Downloads\GoogleMLKit\frontend\lib\features\generative\pages\chat_page.dart", "w", encoding="utf-8") as f:
    f.write(text)
print("Done fixing braces")