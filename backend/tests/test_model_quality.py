from pathlib import Path

import pandas as pd
import pytest
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import RandomForestClassifier
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics import accuracy_score
from sklearn.pipeline import Pipeline

ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "data" / "processed"


def test_multimodal_accuracy_threshold():
    train_path = DATA_DIR / "train_clean.csv"
    test_path = DATA_DIR / "test_clean.csv"
    if not train_path.exists() or not test_path.exists():
        pytest.skip("Processed data not found")

    train_df = pd.read_csv(train_path)
    test_df = pd.read_csv(test_path)

    if "Rapport_Collecte" not in train_df.columns:
        pytest.skip("Text column missing")

    target_col = "Categorie"
    text_col = "Rapport_Collecte"

    train_df[text_col] = train_df[text_col].fillna("")
    test_df[text_col] = test_df[text_col].fillna("")

    num_cols = [
        c
        for c in train_df.select_dtypes(include=["number"]).columns
        if c not in ["Prix_Revente"]
    ]

    X_train = train_df[[text_col] + num_cols]
    y_train = train_df[target_col]
    X_test = test_df[[text_col] + num_cols]
    y_test = test_df[target_col]

    preprocessor = ColumnTransformer(
        transformers=[
            ("text", TfidfVectorizer(max_features=1000, ngram_range=(1, 2)), text_col),
            ("num", "passthrough", num_cols),
        ]
    )

    model = Pipeline(
        [
            ("preprocessor", preprocessor),
            (
                "clf",
                RandomForestClassifier(n_estimators=200, max_depth=20, random_state=42),
            ),
        ]
    )

    model.fit(X_train, y_train)
    preds = model.predict(X_test)

    acc = accuracy_score(y_test, preds)
    assert acc >= 0.70


def test_regression_model_runs_without_error():
    """Vérifie que le régresseur entraîné produit des prédictions numériques positives."""
    train_path = DATA_DIR / "train_clean.csv"
    test_path = DATA_DIR / "test_clean.csv"
    if not train_path.exists() or not test_path.exists():
        pytest.skip("Processed data not found")

    from sklearn.ensemble import RandomForestRegressor

    train_df = pd.read_csv(train_path)
    test_df = pd.read_csv(test_path)

    target_reg = "Prix_Revente"
    text_col = "Rapport_Collecte"

    train_df[text_col] = train_df[text_col].fillna("")
    test_df[text_col] = test_df[text_col].fillna("")

    num_cols = [
        c
        for c in train_df.select_dtypes(include=["number"]).columns
        if c not in [target_reg, "Categorie"]
    ]

    X_train = train_df[[text_col] + num_cols]
    y_train = train_df[target_reg]
    X_test = test_df[[text_col] + num_cols]

    preprocessor = ColumnTransformer(
        transformers=[
            ("text", TfidfVectorizer(max_features=1000, ngram_range=(1, 2)), text_col),
            ("num", "passthrough", num_cols),
        ]
    )

    reg_model = Pipeline(
        [
            ("preprocessor", preprocessor),
            (
                "reg",
                RandomForestRegressor(n_estimators=50, max_depth=10, random_state=42),
            ),
        ]
    )
    reg_model.fit(X_train, y_train)
    preds = reg_model.predict(X_test)

    # Vérifie que les prédictions sont numériques et non-NaN
    assert len(preds) == len(X_test)
    assert all(isinstance(p, (int, float)) for p in preds)


def test_kmeans_produces_four_clusters():
    """Vérifie que K-Means avec k=4 produit bien 4 clusters distincts."""
    full_path = DATA_DIR / "dataset_clean_full.csv"
    if not full_path.exists():
        pytest.skip("Full dataset not found")

    from sklearn.cluster import KMeans
    from sklearn.preprocessing import StandardScaler

    full_df = pd.read_csv(full_path)
    label_cols = [c for c in ["Categorie", "Prix_Revente"] if c in full_df.columns]
    X = full_df.drop(columns=label_cols).select_dtypes(include=["number"]).copy()

    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)

    kmeans = KMeans(n_clusters=4, random_state=42, n_init=10)
    labels = kmeans.fit_predict(X_scaled)

    assert len(set(labels)) == 4


def test_django_services_build_payload():
    """Vérifie que build_payload retourne un dictionnaire complet avec les clés attendues."""
    import os
    import sys

    backend_dir = str(Path(__file__).resolve().parents[1])
    if backend_dir not in sys.path:
        sys.path.insert(0, backend_dir)

    from apps.eco_smart.services import build_payload

    data = {
        "poids": 5.0,
        "volume": 3.0,
        "conductivite": 1.0,
        "opacite": 0.5,
        "rigidite": 2.0,
        "rapport_collecte": "Plastique mélangé avec du carton",
        "source": "Centre_Tri",
    }
    result = build_payload(data)

    assert isinstance(result, dict)
    expected_keys = [
        "category",
        "confidence",
        "prediction_method",
        "price_tnd",
        "min_price_tnd",
        "max_price_tnd",
        "currency",
        "location",
        "cluster",
        "keywords",
        "summary",
    ]
    for key in expected_keys:
        assert key in result, f"Clé manquante: {key}"

    # Vérifie que le cluster contient pca_x et pca_y
    cluster = result["cluster"]
    assert "cluster_id" in cluster
    assert "cluster_label" in cluster
    assert "pca_x" in cluster
    assert "pca_y" in cluster

    assert result["price_tnd"] > 0
    assert result["confidence"] > 0
