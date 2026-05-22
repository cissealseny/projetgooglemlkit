from pathlib import Path

import pandas as pd
import pytest
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline

ROOT = Path(__file__).resolve().parents[2]
RAW_DATA = ROOT / "backend" / "dataset_ProjetML_2026.csv"


def test_nlp_vectorization_pipeline():
    if not RAW_DATA.exists():
        pytest.skip(f"Missing dataset: {RAW_DATA}")

    df = pd.read_csv(RAW_DATA)
    if "Rapport_Collecte" not in df.columns or "Categorie" not in df.columns:
        pytest.skip("Missing required columns for NLP test")

    df = df.dropna(subset=["Rapport_Collecte", "Categorie"]).copy()
    if len(df) < 50:
        pytest.skip("Not enough rows for NLP test")

    X_train, X_test, y_train, y_test = train_test_split(
        df["Rapport_Collecte"].astype(str),
        df["Categorie"],
        test_size=0.2,
        random_state=42,
        stratify=df["Categorie"],
    )

    pipe = Pipeline(
        [
            ("vec", TfidfVectorizer(ngram_range=(1, 2), min_df=2)),
            ("clf", LogisticRegression(max_iter=2000)),
        ]
    )
    pipe.fit(X_train, y_train)
    preds = pipe.predict(X_test)

    acc = accuracy_score(y_test, preds)
    assert acc >= 0.70
