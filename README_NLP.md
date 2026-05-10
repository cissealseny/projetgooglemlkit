# README NLP

Documentation fonctionnelle dediee au module NLP (Traitement du langage naturel).

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

Le module NLP permet d'analyser, transformer et interpreter du texte en mode hybride:
- local (ML Kit)
- distant (backend Django)

## 2. Perimetre fonctionnel

Le module couvre:
- analyse de sentiment
- extraction d'entites
- detection de langue
- traduction
- resume automatique
- classification de texte
- smart reply (local)

## 3. Fonctionnalites detaillees

### 3.1 Analyse de sentiment
- Objectif: evaluer la polarite emotionnelle d'un texte (positif, neutre, negatif).
- Entree: un texte libre (`text`) et un provider optionnel (`auto`, `google`, `huggingface`).
- Traitement:
  1. le backend valide la charge utile.
  2. il choisit le provider selon la configuration et la disponibilite.
  3. il calcule un score de sentiment et une intensite (magnitude).
- Sortie: label de sentiment, score numerique, metadonnees provider.
- Cas d'usage: qualifier des avis clients, filtrer des retours negatifs, prioriser des tickets.

### 3.2 Extraction d'entites
- Objectif: detecter automatiquement les elements nommes dans un texte.
- Entree: texte libre, langue/provider selon mode.
- Traitement:
  1. en local: ML Kit extrait les entites directement sur l'appareil.
  2. en distant: le backend utilise Google NLP ou HuggingFace NER.
  3. les entites sont normalisees dans une structure commune.
- Sortie: liste d'entites avec type, score de confiance/salience et positions possibles.
- Cas d'usage: extraction de noms, adresses, dates d'un compte-rendu ou d'un email.

### 3.3 Detection de langue
- Objectif: identifier la langue principale d'un texte avant traduction ou classement.
- Entree: texte utilisateur.
- Traitement:
  1. detection probabiliste de la langue dominante.
  2. estimation de probabilites pour langues alternatives.
- Sortie: code langue principal (ex: `fr`, `en`) + distribution de probabilites.
- Cas d'usage: routage automatique vers la bonne langue cible dans les workflows de traduction.

### 3.4 Traduction
- Objectif: convertir un texte d'une langue source vers une langue cible.
- Entree: `text`, `source_language`, `target_language`, `provider`.
- Traitement:
  1. tentative de traduction distante (backend/provider choisi).
  2. si indisponibilite reseau/timeout en mode distant, fallback local ML Kit.
  3. annotation du resultat pour indiquer le fallback.
- Sortie: texte traduit + metadonnees de langue et provider.
- Cas d'usage: assistant multilingue robuste meme avec connectivite instable.

### 3.5 Resume automatique
- Objectif: condenser un texte long en quelques phrases utiles.
- Entree: texte source + contraintes de longueur (`max_length`, `min_length`).
- Traitement:
  1. le backend applique un modele de summarization.
  2. il calcule les metriques de compression.
- Sortie: resume final, longueur originale, longueur resumee, ratio de compression.
- Cas d'usage: synthese rapide d'articles, de rapports ou de verbatims.

### 3.6 Classification
- Objectif: attribuer une categorie metier a un texte.
- Entree: texte et liste optionnelle de categories.
- Traitement:
  1. comparaison semantique texte vs categories.
  2. scoring et selection de la categorie la plus probable.
- Sortie: categorie retenue et scores associes.
- Cas d'usage: tri automatique de messages (support, vente, incident, information).

### 3.7 Smart Reply
- Objectif: proposer des reponses courtes contextuelles dans une conversation.
- Entree: historique conversationnel (messages locaux/distants).
- Traitement: ML Kit Smart Reply genere des suggestions plausibles en local.
- Sortie: liste de reponses pre-construites prêtes a envoyer.
- Cas d'usage: acceleration des reponses dans un chat mobile.

## 4. Fonctionnement interne

### 4.1 Strategie provider backend

Providers supportes:
- `auto`
- `google`
- `huggingface`

Regles:
1. `auto` selectionne le provider disponible.
2. `google` tente Google Cloud en priorite.
3. `huggingface` force les pipelines Transformers.

Le backend retourne les metadonnees:
- `provider_requested`
- `provider_used`

Effet pratique:
- traçabilite des decisions techniques dans les logs/resultats
- comportement explicable lors des differents environnements (dev, demo, prod)

### 4.2 Traduction resiliente (fallback)

Si la traduction distante echoue sur timeout/reseau:
1. l'appel distant est tente
2. fallback automatique local ML Kit
3. resultat retourne avec `fallbackToLocal=true`

Pourquoi ce choix:
- maintenir un service continu meme en reseau faible
- eviter l'echec bloquant cote utilisateur
- garder une UX stable pendant les demos et en production mobile

## 5. Endpoints API

- `POST /api/v1/nlp/sentiment/`
- `POST /api/v1/nlp/entities/`
- `POST /api/v1/nlp/detect-language/`
- `POST /api/v1/nlp/translate/`
- `POST /api/v1/nlp/summarize/`
- `POST /api/v1/nlp/classify/`
- `GET /api/v1/nlp/history/`

## 6. Parametres cles

Selon endpoint:
- `text`
- `provider` (`auto|google|huggingface`)
- `source_language`
- `target_language`
- `max_length`, `min_length`
- `categories`

## 7. Robustesse et gestion d'erreurs

- erreur 401: session expiree, reconnexion necessaire
- timeout reseau: fallback local (traduction)
- provider indisponible: resultat degrade + message explicite

## 8. Exemples de requetes

### Sentiment

```bash
curl -X POST http://localhost:8000/api/v1/nlp/sentiment/ \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"text":"Ce produit est excellent","provider":"auto"}'
```

### Traduction

```bash
curl -X POST http://localhost:8000/api/v1/nlp/translate/ \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"text":"Bonjour","source_language":"fr","target_language":"en","provider":"auto"}'
```

## 9. Export PDF

```bash
pandoc README_NLP.md -o README_NLP.pdf --toc --number-sections
```
