# README IA Generative

Documentation fonctionnelle dediee au module IA Generative.

## Sommaire

1. Objectif du module
2. Perimetre fonctionnel
3. Fonctionnalites detaillees
4. Fonctionnement interne
5. Endpoints API
6. Parametres cles
7. Robustesse et gestion d'erreurs
8. Exemples de requetes
9. Export PDF

## 1. Objectif du module

Le module IA Generative fournit des capacites de production de contenu et de conversation pour l'application.

## 2. Perimetre fonctionnel

Le module couvre:
- chat conversationnel
- gestion des conversations
- generation de texte
- generation de code
- generation d'embeddings

## 3. Fonctionnalites detaillees

### 3.1 Chat conversationnel
- Objectif: fournir des reponses conversationnelles contextualisees sur plusieurs tours.
- Entree: `message`, `model`, `conversation_id` optionnel, options de generation.
- Traitement:
  1. recuperation de l'historique de conversation.
  2. construction du contexte complet (messages precedents + message courant).
  3. appel du provider choisi.
  4. sauvegarde de la reponse assistant.
- Sortie: reponse textuelle + metadonnees (modele, temps, conversation).
- Cas d'usage: assistant personnel, aide a la redaction, support utilisateur.

### 3.2 Gestion de conversations
- Objectif: organiser les echanges par sessions logiques.
- Entree: operations CRUD (`create/list/get/delete`).
- Traitement: chaque conversation est liee a un utilisateur authentifie.
- Sortie: historique structuré et reutilisable pour reprendre le contexte.
- Cas d'usage: separer les discussions par sujet/projet.

### 3.3 Generation de texte
- Objectif: produire un contenu direct a partir d'une instruction.
- Entree: `prompt`, `model`, `temperature`, `max_tokens`.
- Traitement: generation one-shot sans gestion multi-tour explicite.
- Sortie: texte genere et metadonnees d'execution.
- Cas d'usage: introduction de rapport, emails, propositions marketing.

### 3.4 Generation de code
- Objectif: generer du code conforme a une consigne fonctionnelle.
- Entree: `prompt`, `language`, `model`.
- Traitement:
  1. enrichissement de la consigne (orientation code).
  2. generation avec temperature plus controlee.
- Sortie: bloc de code genere.
- Cas d'usage: prototypes rapides, snippets techniques, aide pedagogue.

### 3.5 Embeddings
- Objectif: representer numeriquement un texte pour calculer des similarites semantiques.
- Entree: `text`, `model` d'embedding.
- Traitement: transformation texte -> vecteur dense.
- Sortie: vecteur + dimension + metadonnees.
- Cas d'usage: recherche semantique, clustering, recommandation de contenu.

## 4. Fonctionnement interne

### 4.1 Pipeline chat

1. reception du message utilisateur
2. creation/recuperation de conversation
3. sauvegarde du message utilisateur
4. construction de l'historique
5. routage vers le provider selon le modele
6. sauvegarde de la reponse assistant
7. retour de la reponse au frontend

Pourquoi ce pipeline:
- garder le contexte conversationnel
- assurer la traçabilite utilisateur
- permettre l'analyse d'usage via historique

### 4.2 Enrichissement geolocalise (optionnel)

Si latitude/longitude/rayon sont fournis et qu'une intention de lieux proches est detectee:
1. collecte Google Maps cote backend
2. classement des lieux
3. injection du contexte lieux dans le prompt
4. retour enrichi avec `places` et `map_center`

Impact fonctionnel:
- transforme un chat generaliste en assistant localise
- fournit des recommandations exploitables (lieux classes)
- connecte IA generative et donnees terrain en temps reel

## 5. Endpoints API

- `POST /api/v1/generative/chat/`
- `GET /api/v1/generative/conversations/`
- `POST /api/v1/generative/conversations/`
- `GET /api/v1/generative/conversations/<id>/`
- `DELETE /api/v1/generative/conversations/<id>/`
- `POST /api/v1/generative/generate-text/`
- `POST /api/v1/generative/generate-code/`
- `POST /api/v1/generative/embedding/`
- `GET /api/v1/generative/history/`

## 6. Parametres cles

Selon endpoint:
- `message`
- `conversation_id`
- `model`
- `temperature`
- `max_tokens`
- `prompt`
- `language`
- `text`

Modeles (prefixes) supportes:
- `ollama:*`
- `hf:*`
- `gemini:*`
- `gpt:*`

## 7. Robustesse et gestion d'erreurs

- timeout sur modele principal: fallback automatique vers `ollama:llama3.2:1b`
- erreurs provider backend: reponse normalisee (`success`, `error`, `processing_time`)
- conservation de l'historique pour reprise de contexte

## 8. Exemples de requetes

### Chat

```bash
curl -X POST http://localhost:8000/api/v1/generative/chat/ \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message":"Donne-moi 3 idees de projet IA","model":"ollama:mistral:7b"}'
```

### Generation de texte

```bash
curl -X POST http://localhost:8000/api/v1/generative/generate-text/ \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"prompt":"Ecris une introduction de rapport sur l IA","model":"gemini:gemini-2.0-flash"}'
```

## 9. Export PDF

```bash
pandoc README_IA_GENERATIVE.md -o README_IA_GENERATIVE.pdf --toc --number-sections
```
