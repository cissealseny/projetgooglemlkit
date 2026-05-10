# Rapport technique du projet GoogleMLKit

## 1. Resume du projet

Le projet est une application IA full-stack composee de:
- un backend Django REST pour l'authentification, l'orchestration IA et la persistance
- un frontend Flutter pour les parcours utilisateurs Vision, NLP, IA Generative et DataHub
- une approche hybride local + cloud:
  - local (mobile): Google ML Kit
  - distant (backend): Google Cloud, Hugging Face, Ollama, OpenAI, Gemini

## 2. Comment le projet est cree (demarche de construction)

### 2.1 Conception initiale

1. Definition des 4 domaines fonctionnels:
   - Vision
   - NLP
   - IA Generative
   - DataHub
2. Choix architecture par couches:
   - Frontend: UI -> Bloc -> Repository -> Services/API
   - Backend: View -> Serializer -> Service -> Model
3. Choix de la strategie hybride:
   - faible latence et offline via ML Kit
   - puissance et historisation via backend

### 2.2 Mise en place backend

1. Creation du projet Django et apps metier
2. Configuration DRF + JWT + CORS
3. Creation des modeles de trace:
   - analyses Vision
   - analyses NLP
   - conversations/messages/generations
   - jobs et records DataHub
4. Exposition d'une API versionnee /api/v1
5. Ajout de documentation Swagger/ReDoc

### 2.3 Mise en place frontend

1. Creation projet Flutter
2. Mise en place DI (GetIt), reseau (Dio), state management (flutter_bloc)
3. Separation par features (auth, vision, nlp, generative, datahub)
4. Ajout des services ML Kit pour execution locale
5. Connexion aux endpoints backend via ApiClient

### 2.4 Evolutions recentes implementees

1. Recherche de lieux dans le chat IA enrichie (Google Places)
2. Limitation a 5 resultats par categorie
3. Persistance des lieux en base
4. Proxy image backend pour masquer la cle API Google
5. Cache court sur le proxy photo pour reduire les appels externes
6. UI chat enrichie avec cartes lieux + tri par categorie

## 3. Architecture technique

## 3.1 Backend

- Framework: Django + Django REST Framework
- Auth: JWT (SimpleJWT)
- DB: MySQL
- Docs API: drf-yasg (Swagger/ReDoc)
- Apps metier:
  - apps/vision
  - apps/nlp
  - apps/generative
  - apps/datahub
  - apps/users

## 3.2 Frontend

- Framework: Flutter (Dart)
- State: flutter_bloc
- DI: get_it
- HTTP: dio
- Routing: go_router
- Stockage local: flutter_secure_storage, shared_preferences, hive

## 3.3 IA et providers

- Vision cloud: google-cloud-vision
- NLP cloud: google-cloud-language
- NLP fallback/local server: transformers + torch
- Generative:
  - ollama
  - transformers
  - google-generativeai (Gemini)
  - openai
- Mobile local:
  - google_mlkit_text_recognition
  - google_mlkit_face_detection
  - google_mlkit_object_detection
  - google_mlkit_image_labeling
  - google_mlkit_barcode_scanning
  - google_mlkit_language_id
  - google_mlkit_translation
  - google_mlkit_entity_extraction
  - google_mlkit_smart_reply

## 4. Codes pertinents a citer dans le rapport

### 4.1 Entree API backend

- Routage global API v1: backend/config/urls.py
- Configuration globale backend: backend/config/settings.py

### 4.2 Vision

- Service metier Vision: backend/apps/vision/services.py
- Endpoints Vision: backend/apps/vision/views.py
- Repository frontend Vision (local + remote): frontend/lib/features/vision/repository/vision_repository.dart
- Service ML Kit Vision: frontend/lib/features/vision/services/mlkit_vision_service.dart

### 4.3 NLP

- Service metier NLP (providers + fallback): backend/apps/nlp/services.py
- Endpoints NLP: backend/apps/nlp/views.py
- Repository frontend NLP: frontend/lib/features/nlp/repository/nlp_repository.dart
- Service ML Kit NLP: frontend/lib/features/nlp/services/mlkit_nlp_service.dart

### 4.4 IA Generative

- Service generatif multi-provider: backend/apps/generative/services.py
- Chat + enrichissement geolocalise: backend/apps/generative/views.py
- Repository frontend generatif: frontend/lib/features/generative/repository/generative_repository.dart
- UI chat enrichie (carte + categories): frontend/lib/features/generative/pages/chat_page.dart

### 4.5 DataHub / Base de donnees

- Collecte APIs externes: backend/apps/datahub/services.py
- Endpoints DataHub + proxy photo: backend/apps/datahub/views.py
- Modeles jobs/records: backend/apps/datahub/models.py
- Validation payloads DataHub: backend/apps/datahub/serializers.py

### 4.6 Couche transverse frontend

- Client HTTP des endpoints: frontend/lib/core/network/api_client.dart
- Injection des dependances: frontend/lib/core/di/injection.dart

## 5. Commandes pertinentes pour presenter le projet

## 5.1 Backend (Windows PowerShell)

~~~powershell
cd backend
python -m venv venv
.\venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
~~~

## 5.2 Frontend Flutter

~~~powershell
cd frontend
flutter pub get
flutter run
~~~

## 5.3 Tests

### Backend
~~~powershell
cd backend
python manage.py test
~~~

### Frontend
~~~powershell
cd frontend
flutter test
~~~

## 5.4 Documentation API

- Swagger: http://localhost:8000/swagger/
- ReDoc: http://localhost:8000/redoc/

## 5.5 Exemples de verification fonctionnelle

### Login
~~~bash
curl -X POST http://localhost:8000/api/v1/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password123"}'
~~~

### Chat geolocalise
~~~bash
curl -X POST http://localhost:8000/api/v1/generative/chat/ \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message":"Trouve des restaurants proches de moi","model":"ollama:mistral:7b","latitude":14.7167,"longitude":-17.4677,"radius_meters":2500}'
~~~

### Proxy photo securise
~~~bash
curl -I "http://localhost:8000/api/v1/datahub/google-place-photo/?photo_reference=PHOTO_REF&max_width=480"
~~~

## 6. Commandes pour produire un PDF de rapport

### Rapport principal cree
~~~powershell
pandoc RAPPORT_TECHNIQUE_PROJET.md -o RAPPORT_TECHNIQUE_PROJET.pdf --toc --number-sections
~~~

### Rapports fonctionnels deja presents
~~~powershell
pandoc README_VISION.md -o README_VISION.pdf --toc --number-sections
pandoc README_NLP.md -o README_NLP.pdf --toc --number-sections
pandoc README_IA_GENERATIVE.md -o README_IA_GENERATIVE.pdf --toc --number-sections
pandoc README_DATAHUB_BASE_DONNEES.md -o README_DATAHUB_BASE_DONNEES.pdf --toc --number-sections
~~~

## 7. Plan de presentation conseille (soutenance)

1. Probleme et objectif produit
2. Architecture globale (frontend/backend)
3. Demonstration Vision (local vs remote)
4. Demonstration NLP (provider auto + fallback)
5. Demonstration Chat IA geolocalise (places + images + categories)
6. DataHub et traçabilite (jobs/records)
7. Securite (JWT, proxy image), robustesse (fallbacks, cache)
8. Limites et perspectives

## 8. Limites et ameliorations futures

- Cache distribue (Redis) pour le proxy photo en production
- Proxy media avec signatures et rate limiting
- Indexation semantique des RawRecord pour RAG
- Monitoring metriques (latence provider, taux fallback, cout API)
- Tests d'integration bout-en-bout automatise
