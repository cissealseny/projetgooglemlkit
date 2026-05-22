# Journal PROMPTS.md — Esprit Critique & Choix IA

Ce fichier documente les interactions avec les outils IA, les suggestions acceptées/rejetées, et les justifications des choix techniques.

---

## Prompt 1 — Choix stratégie d'imputation des valeurs manquantes
- **Contexte** : La colonne `Poids` contient ~10% de NaN. L'IA a suggéré d'utiliser uniquement la médiane.
- **Décision** : Nous avons comparé 3 stratégies (médiane, KNN Imputer, IterativeImputer) sur le RMSE post-imputation.
- **Justification** : KNN Imputer s'est avéré meilleur pour `Poids` car la corrélation avec `Volume` est exploitée. La suggestion IA de la médiane était trop simpliste pour un dataset avec des corrélations inter-features.
- **Rejet** : IterativeImputer rejeté pour ce cas car trop lent avec peu de gain.

## Prompt 2 — Choix du modèle de classification
- **Contexte** : L'IA a recommandé XGBoost comme modèle principal.
- **Décision** : Nous avons gardé RandomForest + GradientBoosting avec GridSearchCV.
- **Justification** : RandomForest offre une meilleure interprétabilité via SHAP et ne nécessite pas de normalisation. L'accuracy de 99.7% avec RF rend XGBoost inutile pour ce dataset.
- **Critique** : Les scores proches de 100% suggèrent que le dataset est synthétique et que les features sont très séparables. Dans un cas réel, ces scores seraient suspects (data leakage possible).

## Prompt 3 — Architecture du pipeline NLP
- **Contexte** : L'IA a proposé d'utiliser directement CamemBERT (BERT français) pour la vectorisation.
- **Décision** : Implémentation progressive : BoW → TF-IDF → Word2Vec/FastText → CamemBERT (bonus).
- **Justification** : TF-IDF suffit pour ce dataset avec des rapports courts et un vocabulaire limité. CamemBERT nécessite GPU et temps d'entraînement non justifiés pour 4 catégories simples.
- **Rejet** : CamemBERT en production principale rejeté pour des raisons de coût computationnel.

## Prompt 4 — Structure du pipeline multimodal
- **Contexte** : L'IA a suggéré d'utiliser `FeatureUnion` pour combiner texte et numérique.
- **Décision** : Utilisation de `ColumnTransformer` à la place.
- **Justification** : `ColumnTransformer` est plus explicite, compatible avec le format DataFrame pandas, et garantit la reproductibilité. `FeatureUnion` nécessite une transformation manuelle préalable des colonnes.

## Prompt 5 — Vérification pipeline DVC
- **Contexte** : Vérifier que `dvc repro` déclenche preprocess + train sans erreur.
- **Attendu** : Liste des étapes exécutées, chemins des outputs, métriques clés.
- **Résultat** : Pipeline en 2 stages (preprocess → train) défini dans `dvc.yaml`. Le fichier `data/metrics.json` contient l'accuracy finale.

## Prompt 6 — Choix de l'API (FastAPI vs Django REST)
- **Contexte** : Le CDC demande FastAPI mais le projet utilise Django REST Framework.
- **Décision** : Maintien de Django REST pour l'application mobile + ajout de `api_inference.py` (FastAPI) pour l'endpoint `/predict` du modèle ML.
- **Justification** : Django REST gère l'authentification, les utilisateurs et la logique métier. FastAPI est plus léger pour l'inférence ML pure. Architecture hybride justifiée.

## Prompt 7 — Correction Word2Vec/FastText
- **Contexte** : Erreur `cannot import name 'triu' from 'scipy.linalg'` avec gensim.
- **Diagnostic** : Incompatibilité entre `gensim >= 4.0` et `scipy >= 1.12` (suppression de `scipy.linalg.triu`).
- **Solution** : Utilisation de `gensim==4.3.2` avec `scipy==1.11.4` (dernière version compatible).
- **Alternative** : Utilisation de `gensim.downloader` qui évite les imports directs.

## Prompt 8 — Monitoring et détection de drift
- **Contexte** : L'IA a suggéré Prometheus + Grafana pour le monitoring.
- **Décision** : Implémentation avec Evidently AI (data drift numérique) + Jensen-Shannon (text drift) + logging JSON.
- **Justification** : Evidently AI est plus adapté au drift ML que Prometheus (orienté infrastructure). La divergence Jensen-Shannon est la mesure standard pour le drift de distributions de texte.
- **Rejet** : Prometheus rejeté comme solution principale de monitoring ML (utilisé uniquement pour les métriques système).
