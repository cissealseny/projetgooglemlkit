from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import OneHotEncoder, StandardScaler

RANDOM_STATE = 42

DATA_PATH = (
    Path(__file__).resolve().parents[1] / "backend" / "dataset_ProjetML_2026.csv"
)
OUTPUT_DIR = Path(__file__).resolve().parents[1] / "data" / "processed"

NUMERIC_COLS = [
    "Poids",
    "Volume",
    "Conductivite",
    "Opacite",
    "Rigidite",
    "Prix_Revente",
]


def _cap_outliers_iqr(df: pd.DataFrame, cols: list[str]) -> pd.DataFrame:
    df = df.copy()
    for col in cols:
        q1 = df[col].quantile(0.25)
        q3 = df[col].quantile(0.75)
        iqr = q3 - q1
        lower = q1 - 1.5 * iqr
        upper = q3 + 1.5 * iqr
        df[col] = df[col].clip(lower=lower, upper=upper)
    return df


def main() -> None:
    if not DATA_PATH.exists():
        raise FileNotFoundError(f"Dataset introuvable: {DATA_PATH}")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    df = pd.read_csv(DATA_PATH)

    # Cast numerics
    for col in NUMERIC_COLS:
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors="coerce")

    # Drop duplicates
    df = df.drop_duplicates()

    # Median imputation for numeric features
    features_num = [c for c in NUMERIC_COLS if c in df.columns and c != "Prix_Revente"]
    df[features_num] = df[features_num].fillna(df[features_num].median())

    # Outlier capping
    df = _cap_outliers_iqr(df, features_num)

    # One-hot encode Source
    df_encoded = df.copy()
    if "Source" in df.columns:
        ohe = OneHotEncoder(handle_unknown="ignore", sparse_output=False)
        ohe_array = ohe.fit_transform(df[["Source"]])
        ohe_cols = ohe.get_feature_names_out(["Source"])
        df_ohe = pd.DataFrame(ohe_array, columns=ohe_cols, index=df.index)
        df_encoded = pd.concat([df.drop(columns=["Source"]), df_ohe], axis=1)

    # Feature engineering
    df_fe = df_encoded.copy()
    if set(["Poids", "Volume"]).issubset(df_fe.columns):
        df_fe["Densite"] = df_fe["Poids"] / df_fe["Volume"].replace(0, np.nan)
    if set(["Conductivite", "Opacite"]).issubset(df_fe.columns):
        df_fe["Cond_Opacite_Ratio"] = df_fe["Conductivite"] / df_fe["Opacite"].replace(
            0, np.nan
        )
    if "Volume" in df_fe.columns:
        df_fe["Log_Volume"] = np.log1p(df_fe["Volume"])

    for col in ["Densite", "Cond_Opacite_Ratio"]:
        if col in df_fe.columns:
            df_fe[col] = df_fe[col].replace([np.inf, -np.inf], np.nan)
            df_fe[col] = df_fe[col].fillna(df_fe[col].median())

    # Standardize numeric features (excluding targets)
    target_cols = [c for c in ["Categorie", "Prix_Revente"] if c in df_fe.columns]
    numeric_cols = df_fe.select_dtypes(include=["number"]).columns.tolist()
    num_features = [c for c in numeric_cols if c not in target_cols]

    scaler = StandardScaler()
    df_scaled = df_fe.copy()
    df_scaled[num_features] = scaler.fit_transform(df_fe[num_features])

    # Remove rows without label for stratification
    if "Categorie" not in df_scaled.columns:
        raise ValueError("La colonne 'Categorie' est requise pour la stratification.")

    df_scaled = df_scaled.dropna(subset=["Categorie"]).copy()

    # Final numeric NaN safety
    for col in df_scaled.select_dtypes(include=["number"]).columns:
        if df_scaled[col].isna().any():
            df_scaled[col] = df_scaled[col].fillna(df_scaled[col].median())

    # Split 70/15/15 stratified
    train_df, temp_df = train_test_split(
        df_scaled,
        test_size=0.30,
        stratify=df_scaled["Categorie"],
        random_state=RANDOM_STATE,
    )
    val_df, test_df = train_test_split(
        temp_df,
        test_size=0.50,
        stratify=temp_df["Categorie"],
        random_state=RANDOM_STATE,
    )

    train_df.to_csv(OUTPUT_DIR / "train_clean.csv", index=False)
    val_df.to_csv(OUTPUT_DIR / "val_clean.csv", index=False)
    test_df.to_csv(OUTPUT_DIR / "test_clean.csv", index=False)
    df_scaled.to_csv(OUTPUT_DIR / "dataset_clean_full.csv", index=False)

    print("Preprocess OK")


if __name__ == "__main__":
    main()
