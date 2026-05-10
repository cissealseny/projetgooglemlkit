# Google ML Kit - Index des README Principaux par Fonctionnalite

Ce fichier sert de point d'entree vers les README principaux organises par grande fonctionnalite.

## README Principaux

1. NLP (traitement du langage)
    - Voir `README_NLP.md`
2. Vision (analyse d'images)
    - Voir `README_VISION.md`
3. IA Generative (chat, generation texte/code, embeddings)
    - Voir `README_IA_GENERATIVE.md`
4. Base de donnees et recuperation des donnees (DataHub)
    - Voir `README_DATAHUB_BASE_DONNEES.md`

## README Techniques Complementaires

- Backend technique global: `backend/README.md`
- Frontend technique global: `frontend/README.md`

## Export PDF (un document par fonctionnalite)

```bash
pandoc README_NLP.md -o README_NLP.pdf --toc --number-sections
pandoc README_VISION.md -o README_VISION.pdf --toc --number-sections
pandoc README_IA_GENERATIVE.md -o README_IA_GENERATIVE.pdf --toc --number-sections
pandoc README_DATAHUB_BASE_DONNEES.md -o README_DATAHUB_BASE_DONNEES.pdf --toc --number-sections
```

## Export PDF (une seule commande)

Script fourni a la racine du projet:
- `generate_all_pdfs.ps1`

Commande:

```powershell
./generate_all_pdfs.ps1
```

Les 4 PDF sont generes dans le dossier `pdf/`.

Option dossier de sortie personnalise:

```powershell
./generate_all_pdfs.ps1 -OutputDir "mes-pdfs"
```

## Licence

MIT
