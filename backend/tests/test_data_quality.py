from pathlib import Path

import pandas as pd
import pytest

ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "data" / "processed"


def _load_csv(name: str) -> pd.DataFrame:
    path = DATA_DIR / name
    if not path.exists():
        pytest.skip(f"Missing dataset: {path}")
    return pd.read_csv(path)


def test_schema_and_no_missing_after_imputation():
    df = _load_csv("train_clean.csv")

    assert "Categorie" in df.columns
    assert "Prix_Revente" in df.columns

    num_cols = df.select_dtypes(include=["number"]).columns
    assert not df[num_cols].isna().any().any()


def test_split_files_exist():
    for name in [
        "train_clean.csv",
        "val_clean.csv",
        "test_clean.csv",
        "dataset_clean_full.csv",
    ]:
        path = DATA_DIR / name
        if not path.exists():
            pytest.skip(f"Missing dataset: {path}")

    train_df = _load_csv("train_clean.csv")
    val_df = _load_csv("val_clean.csv")
    test_df = _load_csv("test_clean.csv")

    total = len(train_df) + len(val_df) + len(test_df)
    assert total > 0
