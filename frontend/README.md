# Frontend Flutter - Documentation Complete des Fonctionnalites

Application mobile Flutter qui consomme l'API Django et execute aussi des traitements IA en local (ML Kit).

Ce document est structure pour une lecture type rapport et conversion PDF.

## Sommaire

1. Objectif frontend
2. Architecture frontend
3. Fonctionnalites detaillees
4. Flux de fonctionnement
5. Robustesse (erreurs, timeout, fallback)
6. Installation et lancement
7. Tests et build
8. Export PDF

## 1. Objectif frontend

Le frontend a 4 roles principaux:
- offrir une experience utilisateur claire pour Vision, NLP, IA generative, DataHub
- orchestrer local/remote selon le besoin
- securiser les appels API avec JWT
- maintenir une UX fluide via cache, fallback et messages explicites

## 2. Architecture frontend

```text
UI Pages
    -> BLoC (events/states)
    -> Repository (abstraction metier)
    -> Services locaux (ML Kit) ou ApiClient (Dio)
    -> Backend Django
```

Structure principale:

```text
lib/
    core/
        di/               # injection de dependances GetIt
        network/          # ApiClient + AuthInterceptor JWT
        router/           # GoRouter
        theme/            # themes et design system
    features/
        auth/
        vision/
        nlp/
        generative/
        datahub/
        home/
        profile/
        dashboard/
        settings/
```

## 3. Fonctionnalites detaillees

### 3.1 Authentification (JWT)

Fonctions:
- inscription / connexion / deconnexion
- maintien de session
- refresh automatique du token en cas de 401

Comment ca marche:
1. `AuthRepository` stocke `access_token` et `refresh_token`.
2. `AuthInterceptor` ajoute automatiquement le header Authorization.
3. Si 401, tentative de refresh via `/auth/token/refresh/`.
4. Si refresh reussi: retry de la requete initiale.
5. Sinon: suppression des tokens et retour etat non authentifie.

### 3.2 Vision

Fonctions disponibles:
- OCR
- detection de visages
- detection d'objets
- etiquetage d'image
- scan de code-barres (local)
- historique des analyses

Mode local/remote:
- local: `MLKitVisionService`
- remote: upload image via `VisionRepository -> ApiClient`

Exemple de logique:
- `VisionBloc` choisit local vs remote selon `event.useLocal`
- le resultat est unifie pour l'UI (success/failure)

### 3.3 NLP

Fonctions:
- sentiment (remote)
- detection de langue (local ou remote)
- traduction (local ou remote)
- extraction d'entites (local ou remote)
- resume (remote)
- classification (remote)
- smart reply (local)

Particularite importante (traduction):
- en mode remote, si timeout/reseau indisponible,
- `NLPBloc` bascule automatiquement vers traduction locale ML Kit,
- puis marque la reponse avec `fallbackToLocal=true` + message warning.

### 3.4 IA Generative

Fonctions:
- liste et creation de conversations
- envoi de messages chat
- generation de texte
- generation de code

Modele et routage:
- choix de modeles locaux/cloud transmis au backend (`ollama:*`, `gemini:*`, `gpt:*`, etc.)

Robustesse chat:
- ajout optimiste du message user dans l'etat local
- si timeout sur modele courant, fallback auto vers `ollama:llama3.2:1b`
- message utilisateur explicite si fallback applique ou echec final

Capacite geolocalisee:
- le frontend peut envoyer latitude/longitude/rayon avec un message
- le backend peut renvoyer des `places` et `map_center`
- l'UI affiche alors la recommandation enrichie

### 3.5 DataHub

Fonctions:
- lancement de collectes YouTube/Facebook/Google Maps
- rafraichissement des jobs et records
- consultation des donnees collectees

Comportement:
- appels API via `ApiClient`
- mise a jour des listes apres chaque collecte
- gestion d'erreurs reseau et permission localisation cote UI

### 3.6 Home, Profile et Dashboard (stats dynamiques)

Fonctions:
- statistiques utilisateur en temps reel
- rafraichissement manuel
- cache persistant local
- horodatage lisible (heure + relatif)
- fenetre temporelle 7j/30j sur dashboard

Comment ca marche:
1. lecture immediate du cache SharedPreferences (`*_cache_v1`).
2. execution d'un fetch reseau.
3. affichage preferentiel du live, sinon fallback cache.
4. sauvegarde du nouveau snapshot dans le cache.
5. si non connecte, affichage degrade sans crash (valeurs fallback).

## 4. Flux de fonctionnement

### 4.1 Flux standard d'une action utilisateur

```text
Page -> Bloc Event -> Repository -> Service local ou API
         -> Bloc State(success/failure) -> Rendu UI
```

### 4.2 Flux OCR (mode selectable)

```text
OCR Page (switch local/remote)
-> PerformOCR(useLocal)
-> VisionBloc
     -> local: MLKitVisionService.performOCR
     -> remote: ApiClient.performOCR (/vision/ocr)
-> resultat affiche
```

### 4.3 Flux traduction resilient

```text
TranslateText(useLocal=false)
-> NLPBloc -> ApiClient.translate
-> erreur reseau/timeout ?
     oui -> translateLocal ML Kit + warning
     non -> resultat remote normal
```

### 4.4 Flux chat resilient

```text
SendMessage(model=X)
-> GenerativeBloc -> ApiClient.chat
-> timeout ?
     oui -> retry model ollama:llama3.2:1b
     non -> affichage reponse normale
```

## 5. Robustesse

Techniques appliquees:
- timeouts reseau differencies NLP et Generative
- interception JWT + retry apres refresh
- fallback local sur traduction
- fallback vers modele plus leger sur chat
- cache local des statistiques
- messages erreurs orientes action utilisateur

## 6. Installation et lancement

### Prerequis
- Flutter SDK 3.2+
- Dart 3.2+
- Backend Django demarre

### Installation

```bash
cd frontend
flutter pub get
```

### Configuration base URL

Configurer l'URL backend dans l'injection reseau (GetIt/Dio), par exemple:

```text
http://VOTRE_IP:8000/api/v1
```

### Run

```bash
flutter run
```

Options:

```bash
flutter run -d chrome
flutter run --debug
flutter run --release
```

## 7. Tests et build

### Tests

```bash
flutter test
flutter test --coverage
flutter test integration_test/
```

### Build

```bash
flutter build apk --release
flutter build appbundle --release
flutter build ios --release
flutter build web --release
```

## 8. Permissions et limites

Permissions mobiles a verifier:
- camera
- internet
- acces media/photo
- localisation (features geolocalisees)

Limites web:
- certaines capacites ML Kit sont limitees en web
- privilegier les endpoints backend pour equivalence fonctionnelle

## Export PDF

```bash
pandoc frontend/README.md -o frontend_README.pdf --toc --number-sections
```

## Licence

MIT License
