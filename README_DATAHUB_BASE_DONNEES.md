# README DataHub et Base de Donnees

Documentation dediee a la recuperation des donnees et a leur stockage.

## Sommaire

1. Objectif du module
2. Perimetre fonctionnel
3. Fonctionnalites detaillees
4. Fonctionnement interne
5. Endpoints API
6. Parametres cles
7. Robustesse et traçabilite
8. Exemples de requetes
9. Export PDF

## 1. Objectif du module

Le module DataHub centralise la collecte de donnees externes et leur stockage structure en base.

## 2. Perimetre fonctionnel

Le module permet de:
- lancer des collectes via APIs officielles
- normaliser les resultats dans un schema unique
- dedoublonner les enregistrements
- suivre les executions de collecte (jobs)

## 3. Fonctionnalites detaillees

### 3.1 Collecte YouTube
- Objectif: recuperer des contenus video lies a une requete metier.
- Entree: `query`, `max_results`, `order`.
- Traitement:
  1. appel YouTube Data API.
  2. extraction des champs utiles (titre, description, auteur, dates, ids).
  3. mapping vers format interne.
- Sortie: records normalises stockables et consultables.
- Cas d'usage: veille sectorielle, suivi de tendances, monitoring de campagnes.

### 3.2 Collecte Facebook
- Objectif: recuperer les publications recentes d'une page.
- Entree: `page_id`, `limit`.
- Traitement:
  1. appel Facebook Graph API.
  2. normalisation des publications et metadonnees.
  3. integration dans le schema commun DataHub.
- Sortie: posts homogenises avec champs unifies.
- Cas d'usage: analyse de communication publique, comparaison de pages.

### 3.3 Collecte Google Maps
- Objectif: recuperer des points d'interet geolocalises autour d'une position.
- Entree: `query`, `latitude`, `longitude`, `radius`, `place_type`, `max_results`.
- Traitement:
  1. appel Places API.
  2. scoring/filtrage des lieux selon contraintes.
  3. normalisation des resultats (adresse, note, coordonnees, liens).
- Sortie: liste de lieux prete pour affichage carte et recommandations IA.
- Cas d'usage: suggestions de restaurants/hotels proches, assistant local.

### 3.4 Consultation des records
- Objectif: donner une vue consolidee des donnees collectees.
- Entree: filtre optionnel `source`.
- Traitement: lecture des `RawRecord` utilisateur avec filtrage.
- Sortie: liste exploitable dans le frontend et les analytics.
- Cas d'usage: verification de collecte, controle qualite donnees.

### 3.5 Suivi des jobs
- Objectif: suivre l'execution technique de chaque collecte.
- Entree: historique des jobs par utilisateur.
- Traitement: journalisation des etats (`running/success/failed`) et compteurs.
- Sortie: traçabilite complete (statut, erreurs, volume, temps).
- Cas d'usage: audit, debugging, pilotage operationnel.

## 4. Fonctionnement interne

Sources integrees:
- YouTube Data API
- Facebook Graph API
- Google Maps Places API

Pipeline ETL applique:
1. `Extract`: appel API source
2. `Transform`: mapping vers `RawRecord`
3. `Load`: stockage via `update_or_create`
4. `Track`: maj de `IngestJob` (`running`, `success`, `failed`)

Details operationnels:
- chaque collecte ouvre un job en statut `running`
- en cas de succes, le nombre de donnees sauvees est enregistre
- en cas d'echec, le message d'erreur est conserve pour diagnostic
- la deduplication evite l'explosion de doublons lors des recollectes

Entites principales:
- `RawRecord`: donnee unifiee stockee
- `IngestJob`: historique d'execution

Cle de deduplication:
- `user + source + external_id`

## 5. Endpoints API

- `POST /api/v1/datahub/collect/youtube/`
- `POST /api/v1/datahub/collect/facebook/`
- `POST /api/v1/datahub/collect/google-maps/`
- `GET /api/v1/datahub/records/`
- `GET /api/v1/datahub/records/?source=youtube`
- `GET /api/v1/datahub/records/?source=facebook`
- `GET /api/v1/datahub/records/?source=google_maps`
- `GET /api/v1/datahub/jobs/`

## 6. Parametres cles

Selon collecte:
- `query`
- `max_results`
- `order`
- `page_id`
- `limit`
- `latitude`, `longitude`
- `radius`
- `place_type`

## 7. Robustesse et tracabilite

- chaque collecte est enveloppee dans un job tracke
- statut et erreurs sont historises
- nombre de donnees recuperees et sauvegardees retourne
- en cas d'echec, job en `failed` avec message explicite

## 8. Exemples de requetes

### Collecte YouTube

```bash
curl -X POST http://localhost:8000/api/v1/datahub/collect/youtube/ \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query":"hotel dakar","max_results":20,"order":"date"}'
```

### Collecte Facebook

```bash
curl -X POST http://localhost:8000/api/v1/datahub/collect/facebook/ \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"page_id":"20531316728","limit":25}'
```

### Collecte Google Maps

```bash
curl -X POST http://localhost:8000/api/v1/datahub/collect/google-maps/ \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query":"restaurant","latitude":14.7167,"longitude":-17.4677,"radius":2500,"place_type":"restaurant","max_results":10}'
```

### Lecture des donnees collectees

```bash
curl "http://localhost:8000/api/v1/datahub/records/?source=youtube" \
  -H "Authorization: Bearer ACCESS_TOKEN"
```

## 9. Export PDF

```bash
pandoc README_DATAHUB_BASE_DONNEES.md -o README_DATAHUB_BASE_DONNEES.pdf --toc --number-sections
```
