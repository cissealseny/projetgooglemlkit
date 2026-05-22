# 🌱 Eco-Smart Classifier

> Système complet de classification et valorisation des déchets combinant Machine Learning supervisé, NLP et pipeline multimodal.

[![CI/CD](https://github.com/cissealseny/projetgooglemlkit/actions/workflows/ci.yml/badge.svg)](https://github.com/cissealseny/projetgooglemlkit/actions)

---

## ⚡ Rejouer le pipeline en 3 commandes

```bash
# 1. Installer les dépendances
pip install -r backend/requirements.txt dvc mlflow scikit-learn pandas numpy joblib

# 2. Reproduire le pipeline complet (prétraitement + entraînement)
dvc repro

# 3. Lancer l'API FastAPI
uvicorn backend.api_inference:app --host 0.0.0.0 --port 8000 --reload
```

Ou avec Docker :

```bash
docker build -t eco-smart-classifier .
docker run -p 8000:8000 eco-smart-classifier
```

---

## 📁 Structure du projet

```
├── backend/               # API Django REST + FastAPI
│   ├── api_inference.py   # Endpoint FastAPI /predict (modèle ML)
│   ├── apps/eco_smart/    # App Django (classification, clustering, NLP)
│   └── tests/             # Tests pytest
├── notebooks/             # Notebooks Jupyter par module
│   ├── 01_nettoyage_feature_engineering.ipynb
│   ├── 02_modelisation_supervisee.ipynb
│   ├── 02b_shap_values.ipynb          # SHAP feature selection
│   ├── 03_nlp_module.ipynb
│   ├── 03b_nlp_word2vec_fasttext.ipynb # Word2Vec/FastText corrigé
│   ├── 04_clustering.ipynb
│   ├── 05_pipeline_multimodal.ipynb
│   ├── 06_mlops_mlflow.ipynb
│   ├── 07_mlflow_registry.ipynb       # MLflow Model Registry
│   └── 07_monitoring_evidently.ipynb  # Monitoring drift
├── scripts/               # Scripts DVC
│   ├── preprocess_data.py
│   └── train_multimodal.py
├── data/processed/        # Données traitées (gérées par DVC)
├── frontend/              # Application Flutter
├── dvc.yaml               # Pipeline DVC
├── Dockerfile             # Image Docker
└── PROMPTS.md             # Journal esprit critique IA
```

---

## 🗂️ Modules

| Module | Notebook | Description |
|--------|----------|-------------|
| 1 — EDA & Nettoyage | `01_*` | Imputation (médiane/KNN/Iterative), outliers, feature engineering |
| 2 — ML Supervisé | `02_*` + `02b_*` | Classification + Régression + SHAP values |
| 3 — NLP | `03_*` + `03b_*` | BoW, TF-IDF, Word2Vec, FastText + comparaison |
| 4 — Clustering | `04_*` | K-Means, Elbow, PCA 2D |
| 5 — Multimodal | `05_*` | Fusion texte+numérique via ColumnTransformer |
| 6 — MLOps | `06_*` + `07_*` | MLflow tracking + Model Registry |
| 7 — Monitoring | `07_monitoring_*` | Evidently AI + Jensen-Shannon + alertes |

---

## 🔗 API

- **FastAPI /predict** : `POST http://localhost:8000/predict` — classification multimodale
- **Django REST** : `http://localhost:8000/api/eco-smart/` — ensemble des endpoints

### Exemple d'appel

```bash
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{
    "Rapport_Collecte": "Lot de bouteilles plastiques PET",
    "Poids": 12.5, "Volume": 5.0,
    "Conductivite": 0.1, "Opacite": 0.8, "Rigidite": 0.3,
    "Source_Centre_Tri": 1.0, "Source_Collecte_Citoyenne": 0.0,
    "Source_Usine_A": 0.0, "Source_Usine_B": 0.0, "Source_nan": 0.0,
    "Densite": 2.5, "Cond_Opacite_Ratio": 0.125, "Log_Volume": 1.791
  }'
```

---

## ☁️ Déploiement Cloud Run

```bash
# Déploiement rapide (nécessite gcloud CLI)
cd backend && chmod +x cloud_run_deploy.sh && ./cloud_run_deploy.sh
```

L'API sera accessible sur une URL publique HTTPS :
- **API** : `https://eco-smart-api-xxxxx.run.app/predict`
- **Docs** : `https://eco-smart-api-xxxxx.run.app/docs`
- **Health** : `https://eco-smart-api-xxxxx.run.app/health`

📖 Guide complet : [`docs/DEPLOY.md`](docs/DEPLOY.md)

---

## 📊 MLflow

```bash
# Lancer l'interface MLflow
cd notebooks && mlflow ui --backend-store-uri sqlite:///mlflow.db
# → http://localhost:5000
```

5+ expériences enregistrées | Modèle en Production dans le Registry

---

## 🧪 Tests

```bash
cd backend && pytest tests/ -v --cov=api_inference --cov-report=term-missing --cov-fail-under=70
```

---

## 📱 Application Flutter

L'application mobile comprend 3 sections :
- **Dashboard Data** : Visualisation du dataset et des clusters PCA
- **Prédiction Manuelle** : Curseurs en temps réel → catégorie + prix
- **Assistant NLP** : Description textuelle → pipeline ML complet
