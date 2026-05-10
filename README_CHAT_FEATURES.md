# Nouvelles Fonctionnalités Avancées du Chat (IA & ML Kit)

Ce document explique les quatre nouvelles fonctionnalités interactives qui ont été intégrées à la page de Chat (`chat_page.dart`). Ces ajouts transforment l'assistant classique en une interface multimodale capable d'interagir par l'image, le texte, les émotions et la voix.

---

## 1. Comment les fonctionnalités ont été mises en place (Côté Chat)

Ces fonctionnalités ont été ajoutées dans le fichier `frontend/lib/features/generative/pages/chat_page.dart`. Pour chaque outil, la logique d'implémentation suit un schéma récurrent :
1. **Interface Utilisateur (UI)** : Ajout d'un bouton dédié (icônes appareil photo, scanner, visage ou micro) dans la barre de saisie (TextField).
2. **Acquisition de la donnée** : Utilisation de `image_picker` pour ouvrir la caméra ou la galerie, ou de `speech_to_text` pour activer le micro.
3. **Traitement Local (ML Kit / STT)** : L'image capturée est passée dans les modèles Google ML Kit (qui tournent 100% en local sur le téléphone) pour en extraire des entités, du texte ou des probabilités de sourire. Pour la voix, le flux audio est traduit en texte natif.
4. **Interaction avec l'IA Générative** : Le résultat de l'analyse ML Kit est injecté dans un "Prompt" (une instruction pré-formatée) et inséré dans la zone de texte, avant d'être envoyé au `GenerativeBloc` (vers Mistral ou Gemini).
5. **Permissions natives** : Le microphone a nécessité l'ajout de `<uses-permission android:name="android.permission.RECORD_AUDIO" />` dans `AndroidManifest.xml` et de clés spécifiques dans `Info.plist` (iOS).

---

## 2. Commandes utilisées pour l'installation

Pour activer ces moteurs d'intelligence artificielle locale, les paquets Flutter suivants ont été ajoutés au projet via le terminal (`dart pub add` / `flutter pub add`) :

```bash
# Pour analyser le contenu d'une image (Ingrédients/Objets)
flutter pub add google_mlkit_image_labeling

# Pour extraire le texte d'un document (OCR)
flutter pub add google_mlkit_text_recognition

# Pour analyser le visage et détecter les émotions (sourire, yeux)
flutter pub add google_mlkit_face_detection

# Pour la reconnaissance vocale et la dictée
flutter pub add speech_to_text
```

---

## 3. Fonctionnement et Utilité de chaque fonctionnalité

Voici à quoi sert chaque icône ajoutée dans le champ de saisie du chat, et comment elle fonctionne en arrière-plan :

### 📸 1. L'assistant Culinaire / Visual Recipe (Image Labeling)
- **Utilité :** Générer une recette (notamment tunisienne) en prenant simplement en photo le contenu de son frigo ou de son plan de travail.
- **Fonctionnement :**
  - Ouvre l'appareil photo.
  - ML Kit _Image Labeling_ analyse la photo et liste les objets détectés (ex: "Food", "Tomato", "Meat").
  - Le chat crée un prompt combinant ces ingrédients et demande à l'IA locale (Mistral/Llama) d'inventer une recette adaptée.

### 📄 2. Le Scanner de Documents (OCR - Reconnaissance de texte)
- **Utilité :** Résumer, expliquer ou traduire un long texte (un contrat, une facture, une note technique) juste en le prenant en photo.
- **Fonctionnement :**
  - Capture du document.
  - ML Kit _Text Recognition_ extrait numériquement tout le texte de l'image (OCR).
  - Le texte brut est envoyé dans le chat avec la consigne automatique : *"Peux-tu m'expliquer ce texte simplement ou m'en faire un résumé clair ?"*.

### 😃 3. L'assistant Émotionnel (Face Detection)
- **Utilité :** Avoir un chatbot emphatique qui s'adapte à l'humeur de l'utilisateur (utile pour les assistants de santé mentale, de motivation, ou juste pour le fun).
- **Fonctionnement :**
  - Ouvre la caméra frontale pour prendre un selfie.
  - ML Kit _Face Detection_ (avec l'option `enableClassification` activée) calcule :
    - La probabilité de sourire (`smilingProbability`).
    - L'ouverture des yeux (`leftEyeOpenProbability`, etc.).
  - Le code déduit une humeur (ex: "très heureux", "fatigué et neutre").
  - Le chat envoie cette information au LLM (ex: *"D'après Google ML Kit, j'ai l'air fatigué. Réponds-moi de manière empathique..."*), et l'IA adapte sa réponse pour réconforter ou encourager l'utilisateur.

### 🎙️ 4. La Dictée Vocale (Speech-to-Text)
- **Utilité :** Permettre à l'utilisateur de parler à l'IA plutôt que de taper sur le petit clavier du téléphone.
- **Fonctionnement :**
  - Au clic prolongé ou simple sur l'icône micro, le système déclenche le service vocal natif OS (Android ou Apple).
  - L'audio est converti en texte en temps réel via l'API `speech_to_text`.
  - Le texte détecté remplit dynamiquement l'espace de saisie de l'utilisateur, prêt à être corrigé ou envoyé directement à l'IA.
