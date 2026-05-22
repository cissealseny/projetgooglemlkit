from __future__ import annotations

import json
from pathlib import Path

import joblib
import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import RandomForestClassifier
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics import accuracy_score
from sklearn.pipeline import Pipeline

DATA_DIR = Path(__file__).resolve().parents[1] / "data" / "processed"
MODEL_PATH = Path(__file__).resolve().parents[1] / "notebooks" / "multimodal_model.pkl"
METRICS_PATH = Path(__file__).resolve().parents[1] / "data" / "metrics.json"


def main() -> None:
    train_df = pd.read_csv(DATA_DIR / "train_clean.csv")
    test_df = pd.read_csv(DATA_DIR / "test_clean.csv")

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
            ("clf", RandomForestClassifier(n_estimators=200, max_depth=20, random_state=42)),
        ]
    )

    model.fit(X_train, y_train)
    preds = model.predict(X_test)
    acc = accuracy_score(y_test, preds)

    MODEL_PATH.parent.mkdir(parents=True, exist_ok=True)
    joblib.dump(model, MODEL_PATH)

    METRICS_PATH.parent.mkdir(parents=True, exist_ok=True)
    METRICS_PATH.write_text(json.dumps({"accuracy": acc}, indent=2), encoding="utf-8")

    print(f"Accuracy: {acc:.4f}")
    print(f"Model saved to: {MODEL_PATH}")


if __name__ == "__main__":
    main()
