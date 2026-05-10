# Backend Django - Documentation Technique et Fonctionnelle

API REST qui alimente l'application Flutter pour les modules Auth, Vision, NLP, IA Generative et DataHub.

Document structure pour lecture technique et conversion PDF.

## Sommaire

1. Role du backend
2. Architecture interne
3. Fonctionnalites detaillees
4. Endpoints complets
5. Parametrage `.env`
6. Installation et lancement
7. Exemples de requetes

## 1. Role du backend

Le backend assure:
- authentification JWT
- validation des donnees entrantes
- routage vers les services IA
- persistance des historiques (analyses, generations, jobs)
- exposition d'une API versionnee (`/api/v1`)

## 2. Architecture interne

```text
Request -> View(APIView/GenericView)
			 -> Serializer (validation)
			 -> Service metier (vision/nlp/generative/datahub)
			 -> Model (historique/trace)
			 -> Response JSON
```

Conventions appliquees:
- tous les modules metiers sont dans `apps/*`
- endpoints proteges par `IsAuthenticated` (sauf auth public)
- mise a jour des compteurs utilisateur sur appels reussis

## 3. Fonctionnalites detaillees

### 3.1 Auth (`/api/v1/auth/*`)

Fonctions:
- register
- login
- logout
- profile
- change-password
- token refresh

Mecanisme:
1. login retourne access + refresh token.
2. access token securise les appels API.
3. refresh permet de renouveler un access expire.

### 3.2 Vision (`/api/v1/vision/*`)

Endpoints metier:
- OCR
- detect-objects
- detect-faces
- label-image
- history

Traitement type (OCR, objets, visages, labels):
1. reception image (multipart)
2. validation serializer
3. execution service vision
4. sauvegarde `ImageAnalysis`
5. incrementation `api_calls_count`
6. retour `analysis_id + result`

Remarque importante:
- selon configuration, le service peut basculer vers des fallbacks locaux.

### 3.3 NLP (`/api/v1/nlp/*`)

Endpoints metier:
- sentiment
- entities
- detect-language
- translate
- summarize
- classify
- history

Logique provider:
- `auto`: selection automatique
- `google`: Google Cloud NLP/Translate (si credentials)
- `huggingface`: pipelines Transformers

Robustesse:
- retour explicite de `provider_used` et `provider_requested`
- fallback/placeholder quand modele indisponible
- traitement coherent meme en environnement partiellement configure

### 3.4 Generative (`/api/v1/generative/*`)

Endpoints metier:
- chat
- conversations (list/create)
- conversations/<id> (read/delete)
- generate-text
- generate-code
- embedding
- history

Routeur de modeles:
- `ollama:*`
- `hf:*`
- `gemini:*`
- `gpt:*`

Comportement du chat:
1. creation/recuperation conversation
2. enregistrement message user
3. construction historique
4. appel provider cible
5. enregistrement message assistant
6. retour `conversation_id`, message et metadonnees

Extension geolocalisee integree:
- si message contient une intention "lieux proches" et que lat/lng sont fournis,
- le backend enrichit le prompt avec des resultats Google Places (via DataHub),
- puis renvoie aussi `places` et `map_center` dans la reponse.

### 3.5 DataHub (`/api/v1/datahub/*`)

Endpoints metier:
- collect/youtube
- collect/facebook
- collect/google-maps
- records
- jobs

Pipeline ETL implemente:
1. creation `IngestJob` en statut `running`
2. extraction via API officielle
3. normalisation des enregistrements
4. stockage par `update_or_create`
5. statut final `success` ou `failed`
6. exposition de la tracabilite via `jobs` et `records`

Deduplication:
- cle logique: `user + source + external_id`

## 4. Endpoints complets

### Auth
- `POST /api/v1/auth/register/`
- `POST /api/v1/auth/login/`
- `POST /api/v1/auth/logout/`
- `GET /api/v1/auth/profile/`
- `PATCH /api/v1/auth/profile/`
- `POST /api/v1/auth/change-password/`
- `POST /api/v1/auth/token/refresh/`

### Vision
- `POST /api/v1/vision/ocr/`
- `POST /api/v1/vision/detect-objects/`
- `POST /api/v1/vision/detect-faces/`
- `POST /api/v1/vision/label-image/`
- `GET /api/v1/vision/history/`

### NLP
- `POST /api/v1/nlp/sentiment/`
- `POST /api/v1/nlp/entities/`
- `POST /api/v1/nlp/detect-language/`
- `POST /api/v1/nlp/translate/`
- `POST /api/v1/nlp/summarize/`
- `POST /api/v1/nlp/classify/`
- `GET /api/v1/nlp/history/`

### Generative
- `POST /api/v1/generative/chat/`
- `GET /api/v1/generative/conversations/`
- `POST /api/v1/generative/conversations/`
- `GET /api/v1/generative/conversations/<id>/`
- `DELETE /api/v1/generative/conversations/<id>/`
- `POST /api/v1/generative/generate-text/`
- `POST /api/v1/generative/generate-code/`
- `POST /api/v1/generative/embedding/`
- `GET /api/v1/generative/history/`

### DataHub
- `POST /api/v1/datahub/collect/youtube/`
- `POST /api/v1/datahub/collect/facebook/`
- `POST /api/v1/datahub/collect/google-maps/`
- `GET /api/v1/datahub/records/?source=<youtube|facebook|google_maps>`
- `GET /api/v1/datahub/jobs/`

### Documentation auto
- Swagger: http://localhost:8000/swagger/
- ReDoc: http://localhost:8000/redoc/

## 5. Parametrage .env

Variables principales:

```env
SECRET_KEY=...
DEBUG=True

# IA generative
GEMINI_API_KEY=...
OPENAI_API_KEY=...
OLLAMA_HOST=http://localhost:11434

# Google Cloud (Vision/NLP)
GOOGLE_CLOUD_PROJECT_ID=...
GOOGLE_APPLICATION_CREDENTIALS=path/to/credentials.json

# NLP provider default: auto|google|huggingface
NLP_PROVIDER=auto

# DataHub
YOUTUBE_API_KEY=...
FACEBOOK_ACCESS_TOKEN=...
```

## 6. Installation et lancement

```bash
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
```

## 7. Exemples de requetes

Tous les endpoints metiers exigent un JWT access token.

### Login

```bash
curl -X POST http://localhost:8000/api/v1/auth/login/ \
	-H "Content-Type: application/json" \
	-d '{"email":"user@example.com","password":"password123"}'
```

### OCR

```bash
curl -X POST http://localhost:8000/api/v1/vision/ocr/ \
	-H "Authorization: Bearer ACCESS_TOKEN" \
	-F "image=@/path/to/image.jpg" \
	-F "language=fr"
```

### Traduction NLP

```bash
curl -X POST http://localhost:8000/api/v1/nlp/translate/ \
	-H "Authorization: Bearer ACCESS_TOKEN" \
	-H "Content-Type: application/json" \
	-d '{"text":"Bonjour","source_language":"fr","target_language":"en","provider":"auto"}'
```

### Chat generatif

```bash
curl -X POST http://localhost:8000/api/v1/generative/chat/ \
	-H "Authorization: Bearer ACCESS_TOKEN" \
	-H "Content-Type: application/json" \
	-d '{"message":"Donne-moi 3 idees de projet IA","model":"ollama:mistral:7b"}'
```

### DataHub YouTube

```bash
curl -X POST http://localhost:8000/api/v1/datahub/collect/youtube/ \
	-H "Authorization: Bearer ACCESS_TOKEN" \
	-H "Content-Type: application/json" \
	-d '{"query":"hotel dakar","max_results":20,"order":"date"}'
```

## Export PDF

```bash
pandoc backend/README.md -o backend_README.pdf --toc --number-sections
```
