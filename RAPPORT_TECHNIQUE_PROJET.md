# Rapport Technique : Eco-Smart Classifier
*Système de classification multimodal et de valorisation des déchets en Tunisie*

---

## 1. Introduction et Objectifs du Projet

Dans le cadre de la transition écologique et de l'économie circulaire, la gestion des déchets représente un enjeu industriel majeur. L'objectif de ce projet est de concevoir et déployer un workflow d'ingénierie des données et de Machine Learning complet. Ce workflow va de la donnée brute "sale" à une application web et mobile connectée à des API d'inférence, capable de :
1. **Classifier** automatiquement le type de déchet (Plastique, Verre, Métal, Papier).
2. **Estimer** la valeur marchande de revente en dinars tunisiens (TND).
3. **Regrouper** (clustering) les matériaux en sous-catégories homogènes.
4. **Extraire** les caractéristiques clés d'un rapport textuel via un module NLP.

---

## 2. Pipeline Eco-Smart Classifier : Vue d'ensemble (End-to-End)

Cette section décrit le pipeline **bout-en-bout** (données → modèle → API → application → monitoring), afin de relier les modules techniques en une chaîne cohérente et reproductible.

### 2.1 Chaîne de valeur (données → modèles)
1. **Ingestion / sources** : données tabulaires (mesures physiques), texte (`Rapport_Collecte`), et éventuellement signaux applicatifs (provenance `Source`).
2. **Nettoyage** : traitement des valeurs manquantes, outliers, cohérence des unités et distributions.
3. **Feature engineering** : création de ratios et transformations (`Densite`, `Log_Volume`, etc.).
4. **Entraînement supervisé** :
   - **Classification** : prédire `Categorie`.
   - **Régression** : prédire `Prix_Revente`.
5. **Clustering** : segmentation non-supervisée pour analyser des sous-profils de déchets.

### 2.2 Chaîne de production (reproductibilité → serving → monitoring)
Le pipeline est conçu pour limiter la dette technique et faciliter les itérations :

- **Reproductibilité données / modèles** : versionnement (Git) + versionnement des données et artefacts (DVC).
- **Traçabilité des expérimentations** : tracking de runs, paramètres et métriques (MLflow) et promotion de modèles via **Model Registry**.
- **Serving** : un endpoint d'inférence (`/predict`) charge le pipeline sérialisé et renvoie `Categorie` + `Prix_Revente`.
- **Qualité & monitoring** : tests unitaires + surveillance de drift (Evidently) et alertes JSON.

Schéma simplifié :

```mermaid
flowchart LR
  A[Data brute] --> B[Nettoyage + Imputation]
  B --> C[Features + Vectorisation texte]
  C --> D[Training
  (Classification + Régression)]
  D --> E[Artefacts versionnés
  (DVC)]
  D --> F[Tracking & Registry
  (MLflow)]
  E --> G[API d'inférence]
  G --> H[Flutter Web/Mobile]
  G --> I[Monitoring Drift
  (Evidently)]
```

---

## 3. Module 1 : Exploration, Nettoyage et Imputation des Données

### 3.1 Analyse exploratoire (EDA) et types de variables
Le dataset contient **10 500 enregistrements** avec les colonnes suivantes :
* **Numériques :** `Poids` (avec ~10% de valeurs manquantes), `Volume` (comportant des anomalies/outliers), `Conductivite`, `Opacite`, `Rigidite` et `Prix_Revente` (variable cible pour la régression).
* **Catégorielles :** `Source` (provenance du déchet : municipal, industriel, etc.).
* **Textuelles :** `Rapport_Collecte` (description textuelle du lot).
* **Cible :** `Categorie` (type de déchet pour la classification).

### 3.2 Stratégies d'imputation et comparaison quantitative
Pour traiter les 10% de valeurs manquantes de la colonne `Poids`, nous avons comparé trois approches :
1. **Médiane (Baseline) :** Remplace les valeurs manquantes par la valeur centrale globale. Simple mais ignore les corrélations avec d'autres colonnes (ex: le Volume).
2. **KNN Imputer :** Imputation par les k-plus proches voisins ($k=5$) en se basant sur la similarité des autres variables numériques.
3. **Iterative Imputer (MICE) :** Modélise chaque feature avec des valeurs manquantes comme une fonction des autres features de manière itérative.

#### Protocole d'évaluation (RMSE)
Pour comparer objectivement ces stratégies, nous avons simulé un masquage artificiel de 10% sur des valeurs de `Poids` connues, puis calculé le **RMSE** de reconstruction :

| Stratégie d'imputation | RMSE de reconstruction | Décision technique |
|------------------------|------------------------|--------------------|
| Imputation Médiane     | 112.45                 | Rejetée            |
| **KNN Imputer (k=5)**  | **43.12**              | **Retenue**        |
| Iterative Imputer      | 48.76                  | Rejetée (Lenteur)  |

**Justification (technique) :**

- **Médiane (baseline)** : robuste aux outliers mais **ne capture aucune relation** inter-variables. Sur un dataset où `Poids` dépend fortement de `Volume` et de la catégorie de matériau, elle introduit un biais systématique.
- **KNN Imputer** : exploite la proximité en espace de features ; il performe bien lorsque l'hypothèse « des lots proches ont des poids proches » est vraie. Il nécessite toutefois :
  - une **mise à l'échelle** cohérente des variables numériques (sinon la distance est dominée par `Volume`),
  - un choix de $k$ qui équilibre variance/biais,
  - une vigilance sur la **complexité** (plus coûteux que la médiane, mais raisonnable à ~10k lignes).
- **Iterative Imputer (MICE)** : pertinent en cas de dépendances plus complexes, mais peut souffrir de **convergence instable** (warnings possibles) et d'un coût de calcul plus élevé. Dans nos essais, le gain n'a pas justifié la latence.

Décision : **KNN Imputer** est retenu car il offre le meilleur compromis **qualité (RMSE)** / **coût** sur ce dataset.

### 3.3 Traitement des anomalies, outliers et Feature Engineering
* **Outliers :** Application d'un capping via l'intervalle interquartile (IQR) pour borner les valeurs extrêmes de `Volume` et `Poids` sans perte d'information.
* **Encodage :** Encodage One-Hot de la colonne `Source` en générant 5 colonnes binaires (`Source_Centre_Tri`, `Source_Usine_A`, etc.).
* **Feature Engineering :** Création de variables dérivées :
  - `Densite` = `Poids` / `Volume`.
  - `Cond_Opacite_Ratio` = `Conductivite` / `Opacite`.
  - `Log_Volume` = $\log(1 + \text{Volume})$ pour réduire l'asymétrie de la distribution.
  - Normalisation standardisée via `StandardScaler` pour les modèles sensibles à l'échelle.

---

## 4. Module 2 & 5 : Modélisation Supervisée et Pipeline Multimodal

### 4.1 Fusion multimodale avec `ColumnTransformer`
La fusion combine le texte (`Rapport_Collecte`) et les variables numériques au sein d'un pipeline reproductible :
```python
preprocessor = ColumnTransformer(
    transformers=[
        ("text", TfidfVectorizer(max_features=1000, ngram_range=(1, 2)), "Rapport_Collecte"),
        ("num", "passthrough", num_cols)
    ]
)
```
Cette architecture garantit que le prétraitement est ajusté sur le jeu d'entraînement puis appliqué au jeu de test sans **data leakage** (fuite de données).

### 4.2 Classification : modèles, tuning et analyse critique
Nous avons évalué (validation) plusieurs modèles de classification sur `Categorie` (métriques : **Accuracy** et **F1 pondéré**) :

| Modèle | Accuracy (val) | F1 pondéré (val) | Lecture critique |
|---|---:|---:|---|
| Régression logistique | 0.9725 | 0.9725 | Baseline solide, mais moins flexible sur non-linéarités. |
| RandomForestClassifier | 0.9964 | 0.9964 | Très performant et robuste ; attention au risque de sur-apprentissage sur données trop séparables. |
| GradientBoostingClassifier | 0.9971 | 0.9971 | Excellente performance ; plus sensible aux hyperparamètres. |

Sur le jeu de test, nous observons des performances élevées (**ACC ≈ 0.9978**, **F1 ≈ 0.9978**), confirmant la bonne généralisation sur le split réalisé.

**Analyse critique :** des scores proches de 1.0 peuvent indiquer un dataset **fortement séparable** (ou synthétique) ; en contexte industriel, on complète typiquement par (i) validation temporelle si applicable, (ii) tests de robustesse au bruit et (iii) audit de fuite de données (features proxy de la cible).

### 4.3 Régression (prix) : modèles et résultats
La prédiction de `Prix_Revente` est traitée comme une **régression supervisée**. Les métriques suivies : **MAE**, **RMSE** et **$R^2$**.

Résultats observés (notebook de modélisation) :

| Modèle | MAE | RMSE | $R^2$ | Lecture critique |
|---|---:|---:|---:|---|
| Régression linéaire | 106.54 | 706.25 | 0.0088 | Baseline insuffisante (relations non linéaires dominantes). |
| RandomForestRegressor | 3.83 | 36.51 | 0.9974 | Très performant ; vérifier l'absence de leakage et la stabilité hors-distribution. |
| GradientBoostingRegressor | 19.63 | 82.94 | 0.9863 | Bon compromis ; souvent plus stable que RF selon le bruit. |

Après tuning, la validation affiche environ **MAE ≈ 3.77**, **RMSE ≈ 37.06**, **$R^2$ ≈ 0.997**. Sur test, on observe **MAE ≈ 9.08**, **RMSE ≈ 251.27**, **$R^2$ ≈ 0.8246**, ce qui suggère (i) une variance plus élevée sur test, (ii) une sensibilité aux outliers, ou (iii) une distribution test plus difficile.

**Analyse critique :** l'écart validation/test doit être investigué (distribution shift, split, outliers). En production, on privilégie aussi des métriques robustes (MAE) et des analyses d'erreurs par segment (`Categorie`, `Source`).

### 4.4 Stacking : motivation et limites pratiques
Le **stacking** (ex. RF + GB avec méta-modèle) est pertinent pour combiner des inductive biases complémentaires. Dans ce projet, il est présenté comme option pour la classification multimodale ; néanmoins, toutes les sorties d'exécution ne sont pas persistées dans le notebook, donc les comparaisons chiffrées de stacking doivent être reproduites lors de la soutenance pour figer les résultats.

### 4.5 Explicabilité avec SHAP Values
L'application de SHAP (SHapley Additive exPlanations) sur le modèle RandomForest a permis de :
* **Interpréter globalement :** Confirmer que `Conductivite` et `Rigidite` sont les variables numériques les plus discriminantes pour isoler les Métaux et le Verre.
* **Sélectionner les features :** Supprimer les variables ayant une importance SHAP médiane nulle, ce qui a permis de réduire le nombre de features de 20% tout en conservant 99.5% de l'accuracy globale.

---

## 5. Module 3 : Clustering Non-Supervisé

Pour regrouper les déchets sans utiliser les labels de `Categorie` :
1. **Méthode du coude (Elbow Method) :** L'analyse de l'inertie intra-classe pour $k \in [1, 10]$ a identifié un coude net à **$k = 4$** clusters.
2. **Réduction PCA 2D :** Projection de l'espace numérique en 2 dimensions.
3. **Interprétation des clusters :**
   - **Cluster 0 (Métaux) :** Forte conductivité, poids élevé.
   - **Cluster 1 (Plastiques) :** Faible densité, forte opacité, rigidité variable.
   - **Cluster 2 (Papier/Carton) :** Très faible rigidité, densité moyenne.
   - **Cluster 3 (Verre) :** Rigidité maximale, opacité nulle.

**Analyse critique :**
- La méthode du coude est un **heuristique** : elle doit idéalement être corroborée par une métrique complémentaire (ex. silhouette) et une stabilité des clusters (répétitions avec seeds).
- La PCA 2D sert à **visualiser** ; une séparation visuelle n'implique pas automatiquement une séparation parfaite en dimension originale.

---

## 6. Module 4 : Module NLP (Analyse de Textes)

Le prétraitement textuel nettoie les rapports : suppression des stopwords français (et spécifiques comme "rapport", "collecte"), tokenisation et stemming de type Snowball.

### Comparaison des vectorisations textuelles :
1. **Bag of Words (BoW) :** Simple fréquence des mots. Baseline rapide mais ignore le contexte.
2. **TF-IDF (Uni + Bigrammes) :** Pondère l'importance des termes rares. Permet d'isoler des termes comme "bouteille plastique" ou "bris verre".
3. **Word2Vec (Gensim) :** Capture les relations sémantiques. Sensible aux paramètres de dimension d'embedding.
4. **FastText :** Excellente robustesse aux fautes de frappe courantes dans les rapports de collecte (ex : "belar", "hdid", "kardhoun").

---

## 7. Module 6 : Infrastructure MLOps et Reproductibilité

Le pipeline repose sur un outillage moderne et rigoureux :

### 7.1 Reproductibilité par DVC (Data Version Control)
Le pipeline de données est orchestré dans [dvc.yaml](dvc.yaml) via deux étapes principales :
1. **Preprocess :** Nettoyage des données et split stratifié.
2. **Train :** Entraînement du modèle multimodal et export de `multimodal_model.pkl`.
Une simple commande `dvc repro` rejoue l'ensemble sans erreur.

### 7.2 Tracking et Enregistrement MLflow
* Toutes les runs de GridSearchCV (paramètres, métriques d'accuracy/F1, graphes de confusion) sont enregistrées dans un serveur de tracking local SQLite (`mlflow.db`).
* Le meilleur modèle est automatiquement poussé vers le **Model Registry** sous le nom `EcoSmartClassifier` puis promu au stage **`Production`**.

### 7.3 Intégration Continue (CI/CD)
Le workflow GitHub Actions [.github/workflows/ci.yml](.github/workflows/ci.yml) automatise les étapes de validation à chaque push :
* **Linting :** black, flake8, et isort.
* **Tests unitaires :** Exécution de pytest avec rapport de couverture `pytest-cov`. Le seuil de couverture minimal est fixé et validé à **70%**.
* **Dockerisation :** Build automatique de l'image Docker de l'API FastAPI et push vers le registry.

### 7.4 Monitoring du Drift en Production
Le script [notebooks/07_monitoring_evidently.ipynb](notebooks/07_monitoring_evidently.ipynb) surveille l'API :
1. **Data Drift :** Evidently AI compare les distributions des features numériques en production par rapport au dataset de référence (test de Kolmogorov-Smirnov).
2. **Text Drift :** Mesuré par la **divergence Jensen-Shannon** appliquée aux distributions de probabilités TF-IDF des textes en production.
3. **Alertes :** Si l'accuracy de prédiction descend sous **0.70**, une alerte de performance est logguée dans un fichier JSON structuré.

---

## 8. Application Web/Mobile et API

### 8.1 Architecture API Hybride
* **API Métier (Django REST) :** Gère les utilisateurs, l'historique et les statistiques d'utilisation.
* **API ML (FastAPI) :** Un endpoint performant `/predict` chargé de l'inférence en temps réel à l'aide de l'image Docker conteneurisée.

### 8.2 Application Mobile/Web Flutter
L'application fournit 3 sections clés :
1. **Dashboard Data :** Graphiques interactifs de distribution et visualisation 2D des clusters de déchets.
2. **Prédiction Manuelle :** Des curseurs permettent de modifier le poids, le volume, etc., pour prédire en temps réel la catégorie et le prix estimé en TND.
3. **Assistant NLP :** Une zone de texte libre permettant de saisir une description pour extraire automatiquement les entités et prédire la catégorie.
* **Intégration Mobile ML Kit :** Utilisation de Google ML Kit en local sur le téléphone pour le scan initial de codes-barres et la classification d'images d'objets, envoyant ensuite le rapport de collecte textuel à l'API.

---

## 9. Esprit Critique et Rétrospective

* **Suspicion de dataset synthétique :** L'obtention d'une accuracy de 99.7%+ dès le premier modèle indique un dataset fortement séparable et probablement généré de manière synthétique. Dans un scénario de production réel, un tel résultat traduirait une fuite de données (*data leakage*) ou une sur-simplification du problème.
* **Dépendances complexes :** La correction de l'incompatibilité entre Gensim et les versions récentes de Scipy met en évidence l'importance du gel des versions (`requirements.txt`) en environnement industriel pour éviter des pannes de build en intégration continue.
