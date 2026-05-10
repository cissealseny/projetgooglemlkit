# README Vision

Documentation fonctionnelle dediee au module Vision.

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

Le module Vision permet l'analyse d'images en mode:
- local (ML Kit)
- distant (backend Django)

## 2. Perimetre fonctionnel

Le module couvre:
- OCR
- detection de visages
- detection d'objets
- etiquetage d'image
- scan de codes (local)

## 3. Fonctionnalites detaillees

### 3.1 OCR
- Objectif: lire automatiquement du texte dans une image (document, affiche, ticket, etc.).
- Entree: image + langue optionnelle (`language`) en mode distant.
- Traitement:
  1. pretraitement image (orientation/resolution selon moteur).
  2. detection des zones de texte.
  3. reconnaissance caractere par caractere puis reconstruction en lignes/blocs.
- Sortie: texte extrait, metadonnees de traitement, id d'analyse en distant.
- Cas d'usage: numerisation de notes, extraction d'infos depuis captures photo.

### 3.2 Detection de visages
- Objectif: localiser les visages presents dans une image.
- Entree: image + option `include_emotions` en distant.
- Traitement:
  1. detection des regions faciales.
  2. estimation d'attributs (selon moteur disponible) et scores associes.
  3. normalisation des resultats pour affichage UI.
- Sortie: nombre de visages, boites de detection, attributs eventuels.
- Cas d'usage: moderation, analytics photo, experiences AR basiques.

### 3.3 Detection d'objets
- Objectif: identifier les objets majeurs dans la scene.
- Entree: image + limite de resultats (`max_results`) en distant.
- Traitement:
  1. detection des objets et localisation.
  2. attribution de classes avec score de confiance.
  3. tri des objets par pertinence/confiance.
- Sortie: liste d'objets detectes avec labels, scores et positions.
- Cas d'usage: inventaire photo, assistance visuelle, categorisation de contenu.

### 3.4 Etiquetage d'image
- Objectif: decrire globalement le contenu d'une image.
- Entree: image + seuil de confiance (`min_confidence`) + nombre max de labels.
- Traitement:
  1. analyse semantique de l'image.
  2. proposition de labels candidats.
  3. filtrage selon seuil et cardinalite demandee.
- Sortie: labels semantiques ordonnes par confiance.
- Cas d'usage: recherche d'images, indexation automatique, tags intelligents.

### 3.5 Scan de codes
- Objectif: decoder rapidement un QR code ou un code-barres.
- Entree: image de la camera ou de galerie.
- Traitement: detection du symbole puis decodage local du contenu.
- Sortie: valeur decodee (texte, URL, identifiant produit, etc.).
- Cas d'usage: check-in, inventaire, ouverture de liens.

## 4. Fonctionnement interne

### 4.1 Pipeline distant

1. upload image en `multipart/form-data`
2. validation serializer
3. traitement service vision
4. sauvegarde en `ImageAnalysis`
5. increment des statistiques d'usage
6. retour avec `analysis_id`

Valeur metier du pipeline distant:
- conserve un historique consultable
- facilite la tracabilite des analyses utilisateur
- permet des usages statistiques dans le dashboard

### 4.2 Pipeline local

1. traitement direct dans l'application via ML Kit
2. affichage immediate du resultat sans reseau

Valeur metier du pipeline local:
- latence faible
- fonctionnement offline
- meilleure confidentialite des images (pas d'upload)

## 5. Endpoints API

- `POST /api/v1/vision/ocr/`
- `POST /api/v1/vision/detect-objects/`
- `POST /api/v1/vision/detect-faces/`
- `POST /api/v1/vision/label-image/`
- `GET /api/v1/vision/history/`

## 6. Parametres cles

Selon endpoint:
- `image` (obligatoire)
- `language` (OCR)
- `max_results` (objets)
- `include_emotions` (visages)
- `max_labels`, `min_confidence` (label-image)

## 7. Robustesse et tracabilite

- mode local disponible pour limiter la dependance reseau
- historique des analyses distantes conserve cote backend
- temps de traitement inclus dans les resultats

## 8. Exemples de requetes

### OCR

```bash
curl -X POST http://localhost:8000/api/v1/vision/ocr/ \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -F "image=@/path/to/image.jpg" \
  -F "language=fr"
```

### Detection objets

```bash
curl -X POST http://localhost:8000/api/v1/vision/detect-objects/ \
  -H "Authorization: Bearer ACCESS_TOKEN" \
  -F "image=@/path/to/image.jpg" \
  -F "max_results=10"
```

## 9. Export PDF

```bash
pandoc README_VISION.md -o README_VISION.pdf --toc --number-sections
```
