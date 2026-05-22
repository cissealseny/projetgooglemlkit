from __future__ import annotations

import json
from pathlib import Path

import joblib
import pandas as pd
from sklearn.cluster import KMeans
from sklearn.compose import ColumnTransformer
from sklearn.decomposition import PCA
from sklearn.ensemble import RandomForestClassifier, RandomForestRegressor
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics import accuracy_score, mean_absolute_error, r2_score
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler

ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "data" / "processed"
MODEL_DIR = ROOT / "notebooks"
METRICS_PATH = ROOT / "data" / "metrics.json"


def main() -> None:
    # 1. Charger les données d'entraînement et de test
    train_df = pd.read_csv(DATA_DIR / "train_clean.csv")
    test_df = pd.read_csv(DATA_DIR / "test_clean.csv")

    target_clf = "Categorie"
    target_reg = "Prix_Revente"
    text_col = "Rapport_Collecte"

    train_df[text_col] = train_df[text_col].fillna("")
    test_df[text_col] = test_df[text_col].fillna("")

    # Les colonnes numériques excluent Categorie et Prix_Revente
    num_cols = [
        c
        for c in train_df.select_dtypes(include=["number"]).columns
        if c not in [target_reg, target_clf]
    ]

    print("Variables numériques identifiées :", num_cols)

    # Préparation des ensembles pour la classification et la régression
    X_train = train_df[[text_col] + num_cols]
    y_train_clf = train_df[target_clf]
    y_train_reg = train_df[target_reg]

    X_test = test_df[[text_col] + num_cols]
    y_test_clf = test_df[target_clf]
    y_test_reg = test_df[target_reg]

    # Preprocessor TF-IDF + passthrough pour les variables numériques
    preprocessor = ColumnTransformer(
        transformers=[
            ("text", TfidfVectorizer(max_features=1000, ngram_range=(1, 2)), text_col),
            ("num", "passthrough", num_cols),
        ]
    )

    # 2. Entraîner le classifieur multimodal
    print("Entraînement du RandomForestClassifier multimodal...")
    clf_model = Pipeline(
        [
            ("preprocessor", preprocessor),
            (
                "clf",
                RandomForestClassifier(n_estimators=200, max_depth=20, random_state=42),
            ),
        ]
    )
    clf_model.fit(X_train, y_train_clf)
    clf_preds = clf_model.predict(X_test)
    clf_acc = accuracy_score(y_test_clf, clf_preds)
    print(f"Accuracy de classification : {clf_acc:.4f}")

    # 3. Entraîner le régresseur multimodal
    print("Entraînement du RandomForestRegressor multimodal...")
    reg_model = Pipeline(
        [
            ("preprocessor", preprocessor),
            (
                "reg",
                RandomForestRegressor(n_estimators=200, max_depth=20, random_state=42),
            ),
        ]
    )
    reg_model.fit(X_train, y_train_reg)
    reg_preds = reg_model.predict(X_test)
    reg_r2 = r2_score(y_test_reg, reg_preds)
    reg_mae = mean_absolute_error(y_test_reg, reg_preds)
    print(f"R² de régression : {reg_r2:.4f} (MAE: {reg_mae:.4f})")

    # 4. Charger dataset_clean_full pour le clustering
    print("Entraînement du clustering K-Means et PCA...")
    full_df = pd.read_csv(DATA_DIR / "dataset_clean_full.csv")

    # Extraire les colonnes numériques pour le clustering (les mêmes que num_cols)
    # Attends, dans le notebook 4, X contient toutes les colonnes numériques standardisées de full_df sauf Categorie et Prix_Revente
    label_cols = [c for c in [target_clf, target_reg] if c in full_df.columns]
    X_clustering = (
        full_df.drop(columns=label_cols).select_dtypes(include=["number"]).copy()
    )

    # Ajuster le StandardScaler
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X_clustering)

    # Entraîner K-Means
    kmeans = KMeans(n_clusters=4, random_state=42, n_init=10)
    kmeans.fit(X_scaled)

    # Entraîner la PCA
    pca = PCA(n_components=2, random_state=42)
    pca.fit(X_scaled)

    print("Clustering entraîné avec succès !")

    # 5. Sauvegarde de tous les modèles dans le dossier notebooks/
    MODEL_DIR.mkdir(parents=True, exist_ok=True)

    joblib.dump(clf_model, MODEL_DIR / "multimodal_model.pkl")
    joblib.dump(reg_model, MODEL_DIR / "regression_model.pkl")
    joblib.dump(scaler, MODEL_DIR / "scaler_model.pkl")
    joblib.dump(kmeans, MODEL_DIR / "kmeans_model.pkl")
    joblib.dump(pca, MODEL_DIR / "pca_model.pkl")

    print(f"Tous les modèles ont été sauvegardés avec succès dans : {MODEL_DIR}")

    # Enregistrer les métriques globales
    METRICS_PATH.parent.mkdir(parents=True, exist_ok=True)
    metrics = {
        "classification_accuracy": clf_acc,
        "regression_r2": reg_r2,
        "regression_mae": reg_mae,
    }
    METRICS_PATH.write_text(json.dumps(metrics, indent=2), encoding="utf-8")
    print(f"Métriques enregistrées dans : {METRICS_PATH}")


if __name__ == "__main__":
    main()
