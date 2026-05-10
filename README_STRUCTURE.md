# Structure Globale du Projet (Full-Stack)

Ce document présente l'architecture globale de notre application, qui est divisée en deux grandes parties : le **Frontend** (l'application mobile en Flutter) et le **Backend** (Le serveur API en Django).

---

## 📂 Arborescence Principale

Voici l'organisation détaillée à la racine du projet :

```text
GoogleMLKit/
│
├── backend/                  # ⚙️ SERVEUR (Django & Python)
│   ├── manage.py             # Script principal de gestion Django
│   ├── requirements.txt      # Liste des dépendances Python (Django, DRF, etc.)
│   ├── .venv/                # Environnement virtuel Python
│   │
│   ├── config/               # Configuration globale de l'API (settings.py, urls.py)
│   │
│   └── apps/                 # Modules (Applications) indépendants de l'API :
│       ├── generative/       # IA Générative : Routage vers Mistral (Ollama) ou Gemini, logique de Chat
│       ├── datahub/          # Géolocalisation : Intégration Google Places & calculs cartographiques
│       ├── vision/           # Modèles de traitement d'images côté serveur (si nécessaire)
│       ├── nlp/              # Traitement du langage naturel lourd
│       └── users/            # Gestion des profils, authentification et sessions
│
├── frontend/                 # 📱 APPLICATION MOBILE (Flutter & Dart)
│   ├── pubspec.yaml          # Dépendances Flutter (bloc, mlkit, google_maps, speech_to_text...)
│   ├── android/              # Code natif Android (Manifest, permissions, Gradle)
│   ├── ios/                  # Code natif iOS (Info.plist, permissions, CocoaPods)
│   │
│   └── lib/                  # Code source principal (Dart)
│       ├── main.dart         # Point d'entrée de l'application mobile
│       ├── app.dart          # Configuration initiale (Thème, Routeur)
│       │
│       ├── core/             # Outils globaux :
│       │   ├── di/           # Injection de dépendances (get_it)
│       │   ├── theme/        # Couleurs de conception, typographie, design tokens
│       │   └── network/      # Clients HTTP pour communiquer avec le backend Django
│       │
│       └── features/         # Fonctionnalités métier modulaires :
│           ├── generative/   # Interface du Chat IA (chat_page.dart), BLoC (generative_bloc.dart)
│           ├── vision/       # Interface pour la lecture de code-barres, détection d'objets, etc.
│           └── nlp/          # Interface pour la traduction, smart reply, etc.
│
├── mes-pdfs/                 # 📄 Dossier de génération des rapports (Scripts d'export Excel/PDF)
├── generate_all_pdfs.ps1     # Script utilitaire d'automatisation
└── README.md                 # Documentations explicatives globales
```

---

## 🔗 Comment les deux parties communiquent-elles ?

L'architecture est totalement **découplée**. 

1. **Le Frontend (Flutter - Client)** gère toute l'interface graphique (UI), les capteurs du téléphone (Caméra via *image_picker*, GPS via *geolocator*, Micro via *speech_to_text*) et le pré-traitement via **Google ML Kit** (qui s'exécute localement sans internet).
2. **Requête HTTP :** Lorsque l'utilisateur valide un message ou demande une information lourde qui nécessite le backend (comme la génération d'un texte par Mistral ou la recherche d'un lieu via Google Places), le `GenerativeBloc` du frontend envoie une requête **HTTP POST** (format JSON) au serveur Django.
3. **Le Backend (Django - Serveur API)** reçoit cette requête via le sous-module `apps/generative` ou `apps/datahub`. Il effectue les calculs, interroge les modèles Ollama/Gemini ou la base de données SQLite, et construit une réponse structurée.
4. **Réponse JSON :** Le backend renvoie sa réponse JSON au frontend.
5. **Mise à jour de l'UI :** Le BLoC Flutter capte cette réponse, met à jour l'état (State), modifie l'interface en direct (la bulle de message de l'IA apparaît), et tout cela de manière asynchrone et fluide.

---
**En résumé :** Flutter s'occupe de *l'expérience utilisateur et de la capture de données (Vision/Voix)*, tandis que Django s'occupe de *la logique complexe, de l'historique et des connexions aux intelligences artificielles lourdes (LLMs)*.
